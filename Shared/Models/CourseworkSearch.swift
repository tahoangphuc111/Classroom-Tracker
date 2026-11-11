import Foundation

/// Prepare Telex alternatives once per query, rather than once per assignment.
public struct CourseworkSearchQuery: Sendable {
    public let normalized: String
    public let tokens: [String]
    private let alternatives: [String]
    private let tokenBytes: [[UInt8]]
    private let alternativeBytes: [[UInt8]]
    private let usesASCII: Bool

    public init(_ text: String) {
        normalized = text.normalizedForVietnameseSearch()
        tokens = normalized.splitSearchTokens()
        alternatives = tokens.map(cleanTelexKeystrokes)
        tokenBytes = tokens.map { Array($0.utf8) }
        alternativeBytes = alternatives.map { Array($0.utf8) }
        usesASCII = tokenBytes.allSatisfy { $0.allSatisfy { $0 < 128 } }
    }

    public func matches(_ index: String) -> Bool {
        guard !tokens.isEmpty else { return true }
        // Preserve Swift's Unicode matching for non-Latin queries.
        guard usesASCII && index.utf8.allSatisfy({ $0 < 128 }) else {
            return tokens.indices.allSatisfy { i in
                index.contains(tokens[i]) ||
                    (alternatives[i] != tokens[i] && index.contains(alternatives[i]))
            }
        }
        return index.withCString { pointer in
            let buffer = FastSearchBuffer(
                ptr: UnsafeRawPointer(pointer).assumingMemoryBound(to: UInt8.self),
                count: index.utf8.count
            )
            for i in tokenBytes.indices {
                if contains(tokenBytes[i], in: buffer) { continue }
                if alternatives[i] == tokens[i] || !contains(alternativeBytes[i], in: buffer) {
                    return false
                }
            }
            return true
        }
    }

    private func contains(_ bytes: [UInt8], in buffer: FastSearchBuffer) -> Bool {
        bytes.withUnsafeBufferPointer { token in
            guard let base = token.baseAddress else { return true }
            return buffer.find(FastSearchBuffer(ptr: base, count: token.count)) >= 0
        }
    }
}

/// Keeps one result per category. Its owner must invalidate through the context
/// whenever source data or filters change. Use only on the owning UI thread.
final class CategoryResultCache<Category: Hashable, Context: Equatable, Value> {
    private struct Entry {
        let context: Context
        let value: Value
    }
    private var entries: [Category: Entry] = [:]

    func value(for category: Category, context: Context, compute: () -> Value) -> Value {
        if let entry = entries[category], entry.context == context {
            return entry.value
        }
        let value = compute()
        entries[category] = Entry(context: context, value: value)
        return value
    }
}
