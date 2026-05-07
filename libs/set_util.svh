`ifndef __SET_UTIL_SVH__
`define __SET_UTIL_SVH__

/**
 * @brief Provides set-style utilities for a native SystemVerilog queue.
 *
 * The container model is `KEY_T[$]`.
 *
 * When `UNIQUE_ELEM == 1`, the queue is treated as a set. Callers are expected
 * to pass normalized input queues that do not contain duplicate elements.
 * Public APIs in this mode do not perform defensive normalization internally.
 *
 * When `UNIQUE_ELEM == 0`, the queue is treated as a general queue. In this
 * mode, `insert`, `count`, `delete`, and `unique_into` are supported. Collection
 * APIs such as `equals`, `contains`, `union`, `intersect`, and `diff` are not
 * currently supported because their duplicate-sensitive contract has not yet
 * been finalized.
 *
 * The `*_into()` family has append-into-result semantics. These APIs insert
 * their computed elements into `result` and do not clear pre-existing result
 * content.
 *
 * @tparam KEY_T element type stored in the queue. It is expected to be a
 *               2-state type comparable with `==`.
 * @tparam UNIQUE_ELEM whether the queue is expected to enforce unique elements.
 *                     The default value is `1`.
 */
class set_util #(type KEY_T = real, bit UNIQUE_ELEM = 1);
    typedef KEY_T set_t[$];

    // ---------------------------------------------------------------------
    // Public API
    // ---------------------------------------------------------------------

    /**
     * @brief Counts how many times `key` appears in `set`.
     *
     * When `UNIQUE_ELEM == 1`, the expected result range is `0` or `1` because
     * callers are required to pass normalized sets. When `UNIQUE_ELEM == 0`,
     * the count may be greater than `1`.
     *
     * @param set queue to inspect.
     * @param key element to count.
     * @return number of occurrences of `key` in `set`.
     */
    extern static function int count(const ref set_t set, input KEY_T key);

    /**
     * @brief Determines whether `rhs` is contained in `lhs`.
     *
     * This API is supported only when `UNIQUE_ELEM == 1`.
     *
     * @param lhs candidate superset queue. Must be a normalized set.
     * @param rhs candidate subset queue. Must be a normalized set.
     * @return `1` if every element of `rhs` is contained in `lhs`; otherwise
     *         returns `0`.
     * @pre `UNIQUE_ELEM == 1`.
     * @pre `lhs` and `rhs` do not contain duplicate elements.
     */
    extern static function bit contains(const ref set_t lhs,
                                        const ref set_t rhs);

    /**
     * @brief Inserts `key` into `set`.
     *
     * When `UNIQUE_ELEM == 1`, insertion succeeds only if `key` does not
     * already exist in the normalized input set. When `UNIQUE_ELEM == 0`, this
     * API behaves as `push_back`.
     *
     * @param set queue to update.
     * @param key element to insert.
     * @return `1` if insertion succeeds; otherwise returns `0`.
     * @post If `UNIQUE_ELEM == 1`, `set` remains normalized.
     */
    extern static function bit insert(ref set_t set, input KEY_T key);

    /**
     * @brief Deletes one occurrence of `key` from `set`.
     *
     * When `UNIQUE_ELEM == 1`, this removes the unique matching element if it
     * exists. When `UNIQUE_ELEM == 0`, this removes one matching occurrence and
     * does not guarantee which matching position is deleted.
     *
     * @param set queue to update.
     * @param key element to delete.
     */
    extern static function void delete(ref set_t set, input KEY_T key);

    /**
     * @brief Determines whether two queues are semantically equal as sets.
     *
     * This API is supported only when `UNIQUE_ELEM == 1`.
     *
     * @param lhs left-hand set operand. Must be normalized.
     * @param rhs right-hand set operand. Must be normalized.
     * @return `1` if `lhs` and `rhs` contain the same set elements; otherwise
     *         returns `0`.
     * @pre `UNIQUE_ELEM == 1`.
     * @pre `lhs` and `rhs` do not contain duplicate elements.
     */
    extern static function bit equals(const ref set_t lhs,
                                      const ref set_t rhs);

    /**
     * @brief Normalizes `queue` in place to a unique-element queue.
     *
     * This API converts a general queue into a set-shaped queue by removing
     * duplicate elements. The intended behavior is analogous to assigning the
     * result of `queue.unique()` back into the original queue.
     *
     * @param queue queue to normalize in place.
     * @post `queue` contains unique elements only.
     */
    extern static function void unique_into(ref set_t queue);

    /**
     * @brief Inserts the union of `lhs` and `rhs` into `result`.
     *
     * This API is supported only when `UNIQUE_ELEM == 1`.
     *
     * @param lhs left-hand set operand. Must be normalized.
     * @param rhs right-hand set operand. Must be normalized.
     * @param result destination queue. Existing content is preserved.
     * @pre `UNIQUE_ELEM == 1`.
     * @pre `lhs`, `rhs`, and any set-like content already in `result` do not
     *      contain duplicate elements.
     * @post `result` contains its original elements plus the union result.
     */
    extern static function void union_into(const ref set_t lhs,
                                           const ref set_t rhs,
                                           ref set_t result);

    /**
     * @brief Returns the pure union of `lhs` and `rhs`.
     *
     * This API is supported only when `UNIQUE_ELEM == 1`.
     *
     * @param lhs left-hand set operand. Must be normalized.
     * @param rhs right-hand set operand. Must be normalized.
     * @return a newly constructed normalized set containing the union result.
     * @pre `UNIQUE_ELEM == 1`.
     * @pre `lhs` and `rhs` do not contain duplicate elements.
     */
    extern static function set_t get_union(const ref set_t lhs,
                                           const ref set_t rhs);

    /**
     * @brief Merges `rhs` into `lhs` using set union semantics.
     *
     * This API is supported only when `UNIQUE_ELEM == 1`.
     *
     * @param lhs destination set to update in place. Must be normalized.
     * @param rhs source set operand. Must be normalized.
     * @pre `UNIQUE_ELEM == 1`.
     * @pre `lhs` and `rhs` do not contain duplicate elements.
     * @post `lhs` remains normalized.
     */
    extern static function void union_with(ref set_t lhs,
                                           const ref set_t rhs);

    /**
     * @brief Inserts the intersection of `lhs` and `rhs` into `result`.
     *
     * This API is supported only when `UNIQUE_ELEM == 1`.
     *
     * @param lhs left-hand set operand. Must be normalized.
     * @param rhs right-hand set operand. Must be normalized.
     * @param result destination queue. Existing content is preserved.
     * @pre `UNIQUE_ELEM == 1`.
     * @pre `lhs`, `rhs`, and any set-like content already in `result` do not
     *      contain duplicate elements.
     * @post `result` contains its original elements plus the intersection
     *       result.
     */
    extern static function void intersect_into(const ref set_t lhs,
                                               const ref set_t rhs,
                                               ref set_t result);

    /**
     * @brief Returns the pure intersection of `lhs` and `rhs`.
     *
     * This API is supported only when `UNIQUE_ELEM == 1`.
     *
     * @param lhs left-hand set operand. Must be normalized.
     * @param rhs right-hand set operand. Must be normalized.
     * @return a newly constructed normalized set containing the intersection
     *         result.
     * @pre `UNIQUE_ELEM == 1`.
     * @pre `lhs` and `rhs` do not contain duplicate elements.
     */
    extern static function set_t get_intersect(const ref set_t lhs,
                                               const ref set_t rhs);

    /**
     * @brief Replaces `lhs` with the intersection of `lhs` and `rhs`.
     *
     * This API is supported only when `UNIQUE_ELEM == 1`.
     *
     * @param lhs destination set to update in place. Must be normalized.
     * @param rhs source set operand. Must be normalized.
     * @pre `UNIQUE_ELEM == 1`.
     * @pre `lhs` and `rhs` do not contain duplicate elements.
     * @post `lhs` remains normalized.
     */
    extern static function void intersect_with(ref set_t lhs,
                                               const ref set_t rhs);

    /**
     * @brief Inserts the difference `lhs - rhs` into `result`.
     *
     * This API is supported only when `UNIQUE_ELEM == 1`.
     *
     * @param lhs left-hand set operand. Must be normalized.
     * @param rhs right-hand set operand. Must be normalized.
     * @param result destination queue. Existing content is preserved.
     * @pre `UNIQUE_ELEM == 1`.
     * @pre `lhs`, `rhs`, and any set-like content already in `result` do not
     *      contain duplicate elements.
     * @post `result` contains its original elements plus the difference result.
     */
    extern static function void diff_into(const ref set_t lhs,
                                          const ref set_t rhs,
                                          ref set_t result);

    /**
     * @brief Returns the pure difference `lhs - rhs`.
     *
     * This API is supported only when `UNIQUE_ELEM == 1`.
     *
     * @param lhs left-hand set operand. Must be normalized.
     * @param rhs right-hand set operand. Must be normalized.
     * @return a newly constructed normalized set containing the difference
     *         result.
     * @pre `UNIQUE_ELEM == 1`.
     * @pre `lhs` and `rhs` do not contain duplicate elements.
     */
    extern static function set_t get_diff(const ref set_t lhs,
                                          const ref set_t rhs);

    /**
     * @brief Replaces `lhs` with the difference `lhs - rhs`.
     *
     * This API is supported only when `UNIQUE_ELEM == 1`.
     *
     * @param lhs destination set to update in place. Must be normalized.
     * @param rhs source set operand. Must be normalized.
     * @pre `UNIQUE_ELEM == 1`.
     * @pre `lhs` and `rhs` do not contain duplicate elements.
     * @post `lhs` remains normalized.
     */
    extern static function void diff_with(ref set_t lhs,
                                          const ref set_t rhs);

    // ---------------------------------------------------------------------
    // Private helpers
    // ---------------------------------------------------------------------

    /**
     * @brief Determines whether `key` appears at least once in `set`.
     *
     * @param set queue to inspect.
     * @param key element to test.
     * @return `1` if `key` appears in `set`; otherwise returns `0`.
     */
    extern static function bit _has(const ref set_t set, input KEY_T key);
endclass : set_util

function int set_util::count(const ref set_t set, input KEY_T key);
    set_t found;

    found = set.find(item) with (item == key);
    return found.size();
endfunction : count

function bit set_util::contains(const ref set_t lhs, const ref set_t rhs);
    foreach (rhs[i]) begin
        if (!_has(lhs, rhs[i]))
            return 0;
    end

    return 1;
endfunction : contains

function bit set_util::insert(ref set_t set, input KEY_T key);
    if (UNIQUE_ELEM) begin
        if (_has(set, key))
            return 0;
    end

    set.push_back(key);
    return 1;
endfunction : insert

function void set_util::delete(ref set_t set, input KEY_T key);
    int found_idx[$];

    found_idx = set.find_index(item) with (item == key);
    if (found_idx.size() != 0)
        set.delete(found_idx[0]);
endfunction : delete

function bit set_util::equals(const ref set_t lhs, const ref set_t rhs);
    if (lhs.size() != rhs.size())
        return 0;

    return contains(lhs, rhs);
endfunction : equals

function void set_util::unique_into(ref set_t queue);
    queue = queue.unique();
endfunction : unique_into

function void set_util::union_into(const ref set_t lhs,
                                   const ref set_t rhs,
                                   ref set_t result);
    foreach (lhs[i])
        void'(insert(result, lhs[i]));

    foreach (rhs[i])
        void'(insert(result, rhs[i]));
endfunction : union_into

function set_util::set_t set_util::get_union(const ref set_t lhs,
                                             const ref set_t rhs);
    set_t result;

    union_into(lhs, rhs, result);
    return result;
endfunction : get_union

function void set_util::union_with(ref set_t lhs, const ref set_t rhs);
    foreach (rhs[i])
        void'(insert(lhs, rhs[i]));
endfunction : union_with

function void set_util::intersect_into(const ref set_t lhs,
                                       const ref set_t rhs,
                                       ref set_t result);
    foreach (lhs[i]) begin
        if (_has(rhs, lhs[i]))
            void'(insert(result, lhs[i]));
    end
endfunction : intersect_into

function set_util::set_t set_util::get_intersect(const ref set_t lhs,
                                                 const ref set_t rhs);
    set_t result;

    intersect_into(lhs, rhs, result);
    return result;
endfunction : get_intersect

function void set_util::intersect_with(ref set_t lhs, const ref set_t rhs);
    set_t result;

    intersect_into(lhs, rhs, result);
    lhs = result;
endfunction : intersect_with

function void set_util::diff_into(const ref set_t lhs,
                                  const ref set_t rhs,
                                  ref set_t result);
    foreach (lhs[i]) begin
        if (!_has(rhs, lhs[i]))
            void'(insert(result, lhs[i]));
    end
endfunction : diff_into

function set_util::set_t set_util::get_diff(const ref set_t lhs,
                                            const ref set_t rhs);
    set_t result;

    diff_into(lhs, rhs, result);
    return result;
endfunction : get_diff

function void set_util::diff_with(ref set_t lhs, const ref set_t rhs);
    set_t result;

    diff_into(lhs, rhs, result);
    lhs = result;
endfunction : diff_with

function bit set_util::_has(const ref set_t set, input KEY_T key);
    return count(set, key) != 0;
endfunction : _has

`endif
