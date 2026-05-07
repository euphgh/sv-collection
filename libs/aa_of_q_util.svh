`ifndef __AA_OF_Q_UTIL_SVH__
`define __AA_OF_Q_UTIL_SVH__

`include "aa_util.svh"

/**
 * @brief Provides multimap-style utilities for an associative array whose
 * values are queues of `VAL_T`.
 *
 * The container model is `KEY_T -> VAL_T[$]`.
 *
 * At the key level, this class behaves like a map-like container. At the value
 * level, each queue delegates its semantic behavior to
 * `set_util#(VAL_T, UNIQUE_ELEM)`.
 *
 * A normalized `aa_of_q_t` must satisfy the following invariant: every visible
 * key maps to a non-empty queue. Public APIs in this class require normalized
 * input operands, and any `aa_of_q_t` returned by this class is expected to be
 * normalized as well.
 *
 * When `UNIQUE_ELEM == 1`, each value queue is expected to behave as a set.
 * When `UNIQUE_ELEM == 0`, this class still delegates value-queue behavior to
 * `set_util`; the exact semantics of `equals`, `contains`, `merge`,
 * `intersect`, `diff`, and `get_values` therefore follow the corresponding
 * `set_util#(VAL_T, UNIQUE_ELEM)` contract.
 *
 * @tparam KEY_T key type of the associative array. It is expected to be a
 *               hashable 2-state type.
 * @tparam VAL_T element type stored in each value queue. It is expected to be
 *               a 2-state type comparable with `==`.
 * @tparam UNIQUE_ELEM whether each value queue enforces unique elements
 *                     through `set_util`. The default value is `1`.
 */
class aa_of_q_util #(
    type KEY_T = logic [7:0],
    type VAL_T = logic [31:0],
    bit UNIQUE_ELEM = 1
);
    typedef VAL_T val_q_t[$];
    typedef set_util#(KEY_T) key_set_util;
    typedef set_util#(VAL_T, UNIQUE_ELEM) val_set_util;
    typedef val_q_t aa_of_q_t[KEY_T];
    typedef key_set_util::set_t key_set_t;
    typedef val_set_util::set_t val_set_t;

    // ---------------------------------------------------------------------
    // Public API
    // ---------------------------------------------------------------------

    /**
     * @brief Determines whether two multimap containers are semantically equal.
     *
     * Equality is defined on both the visible key domain and the value queue of
     * each visible key. Per-key queue comparison delegates to `val_set_util`.
     *
     * @param lhs left-hand multimap operand. Must be normalized.
     * @param rhs right-hand multimap operand. Must be normalized.
     * @return `1` if both operands expose the same visible keys and each key
     *         maps to an equivalent value queue; otherwise returns `0`.
     * @pre `lhs` and `rhs` do not contain keys mapped to empty queues.
     */
    extern static function bit equals(
        const ref aa_of_q_t lhs,
        const ref aa_of_q_t rhs
    );

    /**
     * @brief Determines whether `rhs` is contained in `lhs`.
     *
     * Containment is evaluated key by key. A key visible in `rhs` must also be
     * visible in `lhs`. The associated value queue of `rhs[key]` must be
     * contained in `lhs[key]` according to `val_set_util` semantics.
     *
     * @param lhs candidate superset multimap. Must be normalized.
     * @param rhs candidate subset multimap. Must be normalized.
     * @return `1` if every visible key and value in `rhs` is contained in
     *         `lhs`; otherwise returns `0`.
     * @pre `lhs` and `rhs` do not contain keys mapped to empty queues.
     */
    extern static function bit contains(
        const ref aa_of_q_t lhs,
        const ref aa_of_q_t rhs
    );

    /**
     * @brief Inserts one value into the queue associated with `key`.
     *
     * If `key` does not yet exist, this API creates a new visible mapping for
     * the key. The insertion policy for the value queue delegates to
     * `val_set_util::insert`.
     *
     * @param a multimap to update. Must be normalized before the call.
     * @param key key to insert into.
     * @param value value to be inserted under `key`.
     * @return `1` if the delegated insertion succeeds; otherwise returns `0`.
     * @pre `a` does not contain keys mapped to empty queues.
     * @post `a` remains normalized.
     */
    extern static function bit insert(
        ref aa_of_q_t a,
        input KEY_T key,
        input VAL_T value
    );

    /**
     * @brief Determines whether all keys in `keys` are visible in `a`.
     *
     * A key backed by an empty queue is not a visible key of a normalized
     * `aa_of_q_t`.
     *
     * @param a multimap to inspect. Must be normalized.
     * @param keys key set to check.
     * @return `1` if every key in `keys` exists as a visible key in `a`;
     *         otherwise returns `0`.
     * @pre `a` does not contain keys mapped to empty queues.
     */
    extern static function bit contains_key_set(
        const ref aa_of_q_t a,
        const ref key_set_t keys
    );

    /**
     * @brief Determines whether `value` appears under any visible key.
     *
     * @param a multimap to inspect. Must be normalized.
     * @param value value to search for.
     * @return `1` if at least one visible key contains `value`; otherwise
     *         returns `0`.
     * @pre `a` does not contain keys mapped to empty queues.
     */
    extern static function bit has_value(
        const ref aa_of_q_t a,
        input VAL_T value
    );

    /**
     * @brief Writes the merge of `lhs` and `rhs` into `result`.
     *
     * The intended key-level contract is key union. For a key present in both
     * operands, the result queue is derived by delegating to `val_set_util`.
     *
     * @param lhs left-hand multimap operand. Must be normalized.
     * @param rhs right-hand multimap operand. Must be normalized.
     * @param result output multimap that receives the full merge result.
     * @pre `lhs` and `rhs` do not contain keys mapped to empty queues.
     * @post `result` is normalized.
     */
    extern static function void merge_into(
        const ref aa_of_q_t lhs,
        const ref aa_of_q_t rhs,
        ref aa_of_q_t result
    );

    /**
     * @brief Returns the merge of `lhs` and `rhs`.
     *
     * @param lhs left-hand multimap operand. Must be normalized.
     * @param rhs right-hand multimap operand. Must be normalized.
     * @return a newly constructed normalized multimap that represents the merge
     *         result.
     * @pre `lhs` and `rhs` do not contain keys mapped to empty queues.
     */
    extern static function aa_of_q_t get_merge(
        const ref aa_of_q_t lhs,
        const ref aa_of_q_t rhs
    );

    /**
     * @brief Merges `rhs` into `lhs` in place.
     *
     * @param lhs destination multimap to be updated in place. Must be
     *            normalized before the call.
     * @param rhs source multimap to merge from. Must be normalized.
     * @pre `lhs` and `rhs` do not contain keys mapped to empty queues.
     * @post `lhs` remains normalized.
     */
    extern static function void merge_with(
        ref aa_of_q_t lhs,
        const ref aa_of_q_t rhs
    );

    /**
     * @brief Writes the intersection of `lhs` and `rhs` into `result`.
     *
     * Only keys that appear in both operands may be retained. For each shared
     * key, the result queue is `val_set_util::get_intersect(lhs[key], rhs[key])`.
     * If that queue is empty, the key is not visible in the result.
     *
     * @param lhs left-hand multimap operand. Must be normalized.
     * @param rhs right-hand multimap operand. Must be normalized.
     * @param result output multimap that receives the full intersection result.
     * @pre `lhs` and `rhs` do not contain keys mapped to empty queues.
     * @post `result` is normalized.
     */
    extern static function void intersect_into(
        const ref aa_of_q_t lhs,
        const ref aa_of_q_t rhs,
        ref aa_of_q_t result
    );

    /**
     * @brief Returns the intersection of `lhs` and `rhs`.
     *
     * @param lhs left-hand multimap operand. Must be normalized.
     * @param rhs right-hand multimap operand. Must be normalized.
     * @return a newly constructed normalized multimap that represents the
     *         intersection result.
     * @pre `lhs` and `rhs` do not contain keys mapped to empty queues.
     */
    extern static function aa_of_q_t get_intersect(
        const ref aa_of_q_t lhs,
        const ref aa_of_q_t rhs
    );

    /**
     * @brief Replaces `lhs` with the intersection of `lhs` and `rhs`.
     *
     * @param lhs destination multimap to be updated in place. Must be
     *            normalized before the call.
     * @param rhs right-hand multimap operand. Must be normalized.
     * @pre `lhs` and `rhs` do not contain keys mapped to empty queues.
     * @post `lhs` remains normalized.
     */
    extern static function void intersect_with(
        ref aa_of_q_t lhs,
        const ref aa_of_q_t rhs
    );

    /**
     * @brief Writes the difference `lhs - rhs` into `result`.
     *
     * Keys present only in `lhs` are retained. For keys present in both
     * operands, the result queue is `val_set_util::get_diff(lhs[key], rhs[key])`.
     * If that queue is empty, the key is not visible in the result.
     *
     * @param lhs left-hand multimap operand. Must be normalized.
     * @param rhs right-hand multimap operand. Must be normalized.
     * @param result output multimap that receives the full difference result.
     * @pre `lhs` and `rhs` do not contain keys mapped to empty queues.
     * @post `result` is normalized.
     */
    extern static function void diff_into(
        const ref aa_of_q_t lhs,
        const ref aa_of_q_t rhs,
        ref aa_of_q_t result
    );

    /**
     * @brief Returns the difference `lhs - rhs`.
     *
     * @param lhs left-hand multimap operand. Must be normalized.
     * @param rhs right-hand multimap operand. Must be normalized.
     * @return a newly constructed normalized multimap that represents the
     *         difference result.
     * @pre `lhs` and `rhs` do not contain keys mapped to empty queues.
     */
    extern static function aa_of_q_t get_diff(
        const ref aa_of_q_t lhs,
        const ref aa_of_q_t rhs
    );

    /**
     * @brief Replaces `lhs` with the difference `lhs - rhs`.
     *
     * @param lhs destination multimap to be updated in place. Must be
     *            normalized before the call.
     * @param rhs right-hand multimap operand. Must be normalized.
     * @pre `lhs` and `rhs` do not contain keys mapped to empty queues.
     * @post `lhs` remains normalized.
     */
    extern static function void diff_with(
        ref aa_of_q_t lhs,
        const ref aa_of_q_t rhs
    );

    /**
     * @brief Returns the set of visible keys.
     *
     * @param a multimap to inspect. Must be normalized.
     * @return a key set containing every visible key in `a`.
     * @pre `a` does not contain keys mapped to empty queues.
     */
    extern static function key_set_t get_keys(const ref aa_of_q_t a);

    /**
     * @brief Returns the flattened set of visible values.
     *
     * This API conceptually traverses all visible keys, flattens their value
     * queues, and accumulates the result through `val_set_util`.
     *
     * @param a multimap to inspect. Must be normalized.
     * @return a value set containing the visible values of `a`.
     * @pre `a` does not contain keys mapped to empty queues.
     */
    extern static function val_set_t get_values(const ref aa_of_q_t a);

    /**
     * @brief Normalizes a multimap in place.
     *
     * This API removes keys whose associated value queue is empty so that the
     * resulting container satisfies the normalized representation required by
     * the rest of this class.
     *
     * @param a multimap to normalize in place.
     * @post `a` does not contain keys mapped to empty queues.
     */
    extern static function void clean(ref aa_of_q_t a);
endclass : aa_of_q_util

function bit aa_of_q_util::equals(
    const ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs
);
    // Implementation notes:
    // 1. Assume lhs and rhs are already normalized as required by the API.
    // 2. Compare visible key domains first.
    // 3. For each shared key, delegate queue comparison to val_set_util.
    // 4. The exact queue comparison semantics, including UNIQUE_ELEM == 0,
    //    follow set_util#(VAL_T, UNIQUE_ELEM).
    return 0;
endfunction : equals

function bit aa_of_q_util::contains(
    const ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs
);
    // Implementation notes:
    // 1. Assume lhs and rhs are already normalized as required by the API.
    // 2. Iterate only visible keys in rhs.
    // 3. Check that each rhs key is visible in lhs.
    // 4. Delegate per-key value containment to val_set_util.
    return 0;
endfunction : contains

function bit aa_of_q_util::insert(
    ref aa_of_q_t a,
    input KEY_T key,
    input VAL_T value
);
    // Implementation notes:
    // 1. Assume a is already normalized as required by the API.
    // 2. Handle the case where key does not yet exist in the associative array.
    // 3. Avoid relying on implicit associative-array creation through read-only
    //    access to a missing key.
    // 4. Delegate actual queue insertion to val_set_util::insert.
    // 5. Preserve normalized form after insertion.
    return 0;
endfunction : insert

function bit aa_of_q_util::contains_key_set(
    const ref aa_of_q_t a,
    const ref key_set_t keys
);
    // Implementation notes:
    // 1. Assume a is already normalized as required by the API.
    // 2. Iterate over the input key set.
    // 3. Check whether each key exists in the visible key domain of a.
    return 0;
endfunction : contains_key_set

function bit aa_of_q_util::has_value(
    const ref aa_of_q_t a,
    input VAL_T value
);
    // Implementation notes:
    // 1. Assume a is already normalized as required by the API.
    // 2. Iterate over each visible key.
    // 3. Delegate membership testing within each queue to val_set_util.
    return 0;
endfunction : has_value

function void aa_of_q_util::merge_into(
    const ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs,
    ref aa_of_q_t result
);
    // Implementation notes:
    // 1. Assume lhs and rhs are already normalized as required by the API.
    // 2. Build result from scratch so *_into fully overwrites the destination.
    // 3. Retain keys that appear in either operand.
    // 4. For a shared key, delegate queue merge behavior to val_set_util.
    // 5. Normalize result before returning it to the caller.
endfunction : merge_into

function aa_of_q_util::aa_of_q_t aa_of_q_util::get_merge(
    const ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs
);
    aa_of_q_t result;

    // Implementation notes:
    // 1. Delegate to merge_into to keep one source of truth.
    // 2. Keep allocation and normalization policy consistent with merge_with.
    return result;
endfunction : get_merge

function void aa_of_q_util::merge_with(
    ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs
);
    // Implementation notes:
    // 1. Assume lhs and rhs are already normalized as required by the API.
    // 2. Prefer implementing this API in terms of merge_into/get_merge.
    // 3. Avoid mutating lhs while iterating over it if that creates simulator-
    //    dependent behavior.
    // 4. Preserve normalized representation after the update.
endfunction : merge_with

function void aa_of_q_util::intersect_into(
    const ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs,
    ref aa_of_q_t result
);
    // Implementation notes:
    // 1. Assume lhs and rhs are already normalized as required by the API.
    // 2. Only shared keys are candidates for the result.
    // 3. For each shared key, compute val_set_util::get_intersect(lhs[key],
    //    rhs[key]).
    // 4. Drop keys whose resulting queue is empty.
    // 5. Normalize result before exposing it.
endfunction : intersect_into

function aa_of_q_util::aa_of_q_t aa_of_q_util::get_intersect(
    const ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs
);
    aa_of_q_t result;

    // Implementation notes:
    // 1. Delegate to intersect_into.
    // 2. Keep empty-key cleanup policy identical to intersect_with.
    return result;
endfunction : get_intersect

function void aa_of_q_util::intersect_with(
    ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs
);
    // Implementation notes:
    // 1. Assume lhs and rhs are already normalized as required by the API.
    // 2. Prefer a two-phase strategy: compute then replace, or collect changes
    //    before mutating lhs.
    // 3. Ensure keys whose post-intersection queue is empty are not retained.
    // 4. Preserve consistency with intersect_into/get_intersect.
endfunction : intersect_with

function void aa_of_q_util::diff_into(
    const ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs,
    ref aa_of_q_t result
);
    // Implementation notes:
    // 1. Assume lhs and rhs are already normalized as required by the API.
    // 2. Retain lhs-only keys as-is.
    // 3. For shared keys, compute val_set_util::get_diff(lhs[key], rhs[key]).
    // 4. Drop keys whose resulting queue is empty.
    // 5. Normalize result before exposing it.
endfunction : diff_into

function aa_of_q_util::aa_of_q_t aa_of_q_util::get_diff(
    const ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs
);
    aa_of_q_t result;

    // Implementation notes:
    // 1. Delegate to diff_into.
    // 2. Keep normalization policy identical to diff_with.
    return result;
endfunction : get_diff

function void aa_of_q_util::diff_with(
    ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs
);
    // Implementation notes:
    // 1. Assume lhs and rhs are already normalized as required by the API.
    // 2. Prefer a two-phase update strategy to avoid mutating lhs while it is
    //    being traversed.
    // 3. Remove keys whose post-difference queue becomes empty.
    // 4. Preserve consistency with diff_into/get_diff.
endfunction : diff_with

function aa_of_q_util::key_set_t aa_of_q_util::get_keys(const ref aa_of_q_t a);
    key_set_t result;

    // Implementation notes:
    // 1. Assume a is already normalized as required by the API.
    // 2. Iterate over the associative-array keys.
    // 3. Delegate key-set insertion to key_set_util.
    return result;
endfunction : get_keys

function aa_of_q_util::val_set_t aa_of_q_util::get_values(const ref aa_of_q_t a);
    val_set_t result;

    // Implementation notes:
    // 1. Assume a is already normalized as required by the API.
    // 2. Traverse every visible key.
    // 3. Flatten values from each queue.
    // 4. Delegate accumulation and resulting semantics to val_set_util.
    return result;
endfunction : get_values

function void aa_of_q_util::clean(ref aa_of_q_t a);
    // Implementation notes:
    // 1. Scan for keys whose associated queue is empty.
    // 2. Avoid deleting keys while iterating over the associative array if that
    //    creates simulator-dependent behavior.
    // 3. Use a two-phase collect-then-delete strategy if needed.
    // 4. Ensure the resulting container satisfies the normalized invariant.
endfunction : clean

`endif
