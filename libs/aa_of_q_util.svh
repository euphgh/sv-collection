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
     * The intended key-level contract is key union. This API updates `result`
     * in place and preserves unrelated existing content. For a key present in
     * either operand, the queue stored at `result[key]` is replaced with the
     * merged queue computed from `lhs` and `rhs`.
     *
     * @param lhs left-hand multimap operand. Must be normalized.
     * @param rhs right-hand multimap operand. Must be normalized.
     * @param result destination multimap to update in place.
     * @pre `lhs` and `rhs` do not contain keys mapped to empty queues.
     * @post `result` remains normalized for the keys this API updates.
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
    static function aa_of_q_t get_merge(
        const ref aa_of_q_t lhs,
        const ref aa_of_q_t rhs
    );
        aa_of_q_t result;

        merge_into(lhs, rhs, result);
        return result;
    endfunction : get_merge

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
     * key, the queue stored at `result[key]` is replaced with
     * `val_set_util::get_intersect(lhs[key], rhs[key])`. If that queue is empty,
     * the existing content at `result[key]` is left unchanged.
     *
     * @param lhs left-hand multimap operand. Must be normalized.
     * @param rhs right-hand multimap operand. Must be normalized.
     * @param result destination multimap to update in place.
     * @pre `lhs` and `rhs` do not contain keys mapped to empty queues.
     * @post `result` remains normalized for the keys this API updates.
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
    static function aa_of_q_t get_intersect(
        const ref aa_of_q_t lhs,
        const ref aa_of_q_t rhs
    );
        aa_of_q_t result;

        intersect_into(lhs, rhs, result);
        return result;
    endfunction : get_intersect

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
     * operands, the queue stored at `result[key]` is replaced with
     * `val_set_util::get_diff(lhs[key], rhs[key])`. If that queue is empty,
     * the existing content at `result[key]` is left unchanged.
     *
     * @param lhs left-hand multimap operand. Must be normalized.
     * @param rhs right-hand multimap operand. Must be normalized.
     * @param result destination multimap to update in place.
     * @pre `lhs` and `rhs` do not contain keys mapped to empty queues.
     * @post `result` remains normalized for the keys this API updates.
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
    static function aa_of_q_t get_diff(
        const ref aa_of_q_t lhs,
        const ref aa_of_q_t rhs
    );
        aa_of_q_t result;

        diff_into(lhs, rhs, result);
        return result;
    endfunction : get_diff

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
    static function key_set_t get_keys(const ref aa_of_q_t a);
        key_set_t result;

        foreach (a[key])
            void'(key_set_util::insert(result, key));

        return result;
    endfunction : get_keys

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
    static function val_set_t get_values(const ref aa_of_q_t a);
        val_set_t result;

        foreach (a[key])
            val_set_util::union_with(result, a[key]);

        return result;
    endfunction : get_values

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
    if (lhs.num() != rhs.num())
        return 0;

    foreach (lhs[key]) begin
        if (!rhs.exists(key))
            return 0;
        if (!val_set_util::equals(lhs[key], rhs[key]))
            return 0;
    end

    return 1;
endfunction : equals

function bit aa_of_q_util::contains(
    const ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs
);
    foreach (rhs[key]) begin
        if (!lhs.exists(key))
            return 0;
        if (!val_set_util::contains(lhs[key], rhs[key]))
            return 0;
    end

    return 1;
endfunction : contains

function bit aa_of_q_util::insert(
    ref aa_of_q_t a,
    input KEY_T key,
    input VAL_T value
);
    val_q_t queue;

    if (a.exists(key))
        queue = a[key];

    if (!val_set_util::insert(queue, value))
        return 0;

    a[key] = queue;
    return 1;
endfunction : insert

function bit aa_of_q_util::contains_key_set(
    const ref aa_of_q_t a,
    const ref key_set_t keys
);
    foreach (keys[i]) begin
        if (!a.exists(keys[i]))
            return 0;
    end

    return 1;
endfunction : contains_key_set

function bit aa_of_q_util::has_value(
    const ref aa_of_q_t a,
    input VAL_T value
);
    foreach (a[key]) begin
        if (val_set_util::count(a[key], value) != 0)
            return 1;
    end

    return 0;
endfunction : has_value

function void aa_of_q_util::merge_into(
    const ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs,
    ref aa_of_q_t result
);
    foreach (lhs[key]) begin
        val_q_t queue;

        queue = lhs[key];
        if (rhs.exists(key))
            val_set_util::union_with(queue, rhs[key]);

        result[key] = queue;
    end

    foreach (rhs[key]) begin
        if (!lhs.exists(key))
            result[key] = rhs[key];
    end
endfunction : merge_into

function void aa_of_q_util::merge_with(
    ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs
);
    aa_of_q_t tmp;

    tmp.delete();
    merge_into(lhs, rhs, tmp);
    lhs = tmp;
endfunction : merge_with

function void aa_of_q_util::intersect_into(
    const ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs,
    ref aa_of_q_t result
);
    val_q_t values;

    foreach (lhs[key]) begin
        if (!rhs.exists(key))
            continue;

        values = val_set_util::get_intersect(lhs[key], rhs[key]);
        if (values.size() != 0)
            result[key] = values;
    end
endfunction : intersect_into

function void aa_of_q_util::intersect_with(
    ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs
);
    aa_of_q_t tmp;

    tmp.delete();
    intersect_into(lhs, rhs, tmp);
    lhs = tmp;
endfunction : intersect_with

function void aa_of_q_util::diff_into(
    const ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs,
    ref aa_of_q_t result
);
    val_q_t values;

    foreach (lhs[key]) begin
        if (!rhs.exists(key)) begin
            result[key] = lhs[key];
            continue;
        end

        values = val_set_util::get_diff(lhs[key], rhs[key]);
        if (values.size() != 0)
            result[key] = values;
    end
endfunction : diff_into

function void aa_of_q_util::diff_with(
    ref aa_of_q_t lhs,
    const ref aa_of_q_t rhs
);
    aa_of_q_t tmp;

    tmp.delete();
    diff_into(lhs, rhs, tmp);
    lhs = tmp;
endfunction : diff_with

function void aa_of_q_util::clean(ref aa_of_q_t a);
    KEY_T keys_to_delete[$];

    foreach (a[key]) begin
        if (a[key].size() == 0)
            keys_to_delete.push_back(key);
    end

    foreach (keys_to_delete[i])
        a.delete(keys_to_delete[i]);
endfunction : clean

`endif
