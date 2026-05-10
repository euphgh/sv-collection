`ifndef __AA_UTIL_SVH__
`define __AA_UTIL_SVH__

`include "set_util.svh"

/**
 * @brief Provides map-style utilities for native associative arrays.
 *
 * The container model is `VAL_T[KEY_T]`.
 *
 * Key-level behavior follows map semantics. Value-level behavior is treated as
 * payload handling and is not normalized into a set. The `get_values` API
 * returns a raw queue view that preserves repeated values.
 *
 * The `*_into()` family uses append-into-result semantics. These APIs insert
 * their computed key/value pairs into `result` and do not clear pre-existing
 * content.
 *
 * @tparam KEY_T key type of the associative array. It is expected to be a
 *               hashable 2-state type.
 * @tparam VAL_T value type stored for each key. It is expected to be a 2-state
 *               type comparable with `==`.
 */
class aa_util #(type KEY_T = int, type VAL_T = real);
    typedef VAL_T aa_t[KEY_T];
    typedef set_util#(KEY_T) key_set_util;
    typedef key_set_util::set_t key_set_t;
    typedef VAL_T val_q_t[$];

    // ---------------------------------------------------------------------
    // Public API
    // ---------------------------------------------------------------------

    /**
     * @brief Determines whether two associative arrays are semantically equal.
     *
     * Equality is defined on both the visible key domain and the value stored
     * for each visible key.
     *
     * @param lhs left-hand associative-array operand.
     * @param rhs right-hand associative-array operand.
     * @return `1` if both operands expose the same keys and each key maps to an
     *         equal value; otherwise returns `0`.
     */
    static function bit equals(const ref aa_t lhs, const ref aa_t rhs);
        if (lhs.num() != rhs.num())
            return 0;

        foreach (lhs[k]) begin
            if (!rhs.exists(k))
                return 0;
            if (lhs[k] != rhs[k])
                return 0;
        end

        return 1;
    endfunction : equals

    /**
     * @brief Determines whether `rhs` is contained in `lhs`.
     *
     * Containment is evaluated key by key. A key visible in `rhs` must also be
     * visible in `lhs`, and the associated value must be equal.
     *
     * @param lhs candidate superset associative array.
     * @param rhs candidate subset associative array.
     * @return `1` if every visible key and value in `rhs` is contained in
     *         `lhs`; otherwise returns `0`.
     */
    static function bit contains(const ref aa_t lhs, const ref aa_t rhs);
        foreach (rhs[k]) begin
            if (!lhs.exists(k))
                return 0;
            if (lhs[k] != rhs[k])
                return 0;
        end

        return 1;
    endfunction : contains

    /**
     * @brief Inserts a new `<key, value>` pair.
     *
     * If `key` already exists, the insertion does nothing and returns `0`.
     * Otherwise the pair is created and the function returns `1`.
     *
     * @param a associative array to update.
     * @param key key to insert.
     * @param value value to associate with the key.
     * @return `1` if insertion succeeds; otherwise returns `0`.
     */
    static function bit insert(ref aa_t a, input KEY_T key, input VAL_T value);
        if (a.exists(key))
            return 0;

        a[key] = value;
        return 1;
    endfunction : insert

    /**
     * @brief Determines whether all keys in `keys` are visible in `a`.
     *
     * This helper exists for callers that want a direct key-set containment
     * check without building an intermediate key projection.
     *
     * @param a associative array to inspect.
     * @param keys key set to check.
     * @return `1` if every key in `keys` exists in `a`; otherwise returns `0`.
     */
    static function bit contains_keys(const ref aa_t a,
                                      const ref key_set_t keys);
        foreach (keys[i]) begin
            if (!a.exists(keys[i]))
                return 0;
        end

        return 1;
    endfunction : contains_keys

    /**
     * @brief Determines whether `value` appears under any visible key.
     *
     * @param a associative array to inspect.
     * @param value value to search for.
     * @return `1` if at least one visible key contains `value`; otherwise
     *         returns `0`.
     */
    static function bit has_value(const ref aa_t a, input VAL_T value);
        foreach (a[k]) begin
            if (a[k] == value)
                return 1;
        end

        return 0;
    endfunction : has_value

    /**
     * @brief Writes the merge of `lhs` and `rhs` into `result`.
     *
     * The key-level contract is key union. For a shared key, `rhs` overrides
     * `lhs`.
     *
     * @param lhs left-hand associative-array operand.
     * @param rhs right-hand associative-array operand.
     * @param result destination associative array.
     * @post `result` keeps its pre-existing keys that are not overwritten by the
     *       merge result.
     */
    static function void merge_into(const ref aa_t lhs,
                                    const ref aa_t rhs,
                                    ref aa_t result);
        foreach (lhs[k])
            result[k] = lhs[k];

        foreach (rhs[k])
            result[k] = rhs[k];
    endfunction : merge_into

    /**
     * @brief Returns the merge of `lhs` and `rhs`.
     *
     * @param lhs left-hand associative-array operand.
     * @param rhs right-hand associative-array operand.
     * @return a newly constructed associative array that represents the merge
     *         result.
     */
    static function aa_t get_merge(const ref aa_t lhs, const ref aa_t rhs);
        aa_t result;

        merge_into(lhs, rhs, result);
        return result;
    endfunction : get_merge

    /**
     * @brief Merges `rhs` into `lhs` in place.
     *
     * @param lhs destination associative array to update in place.
     * @param rhs source associative array to merge from.
     */
    static function void merge_with(ref aa_t lhs, const ref aa_t rhs);
        foreach (rhs[k])
            lhs[k] = rhs[k];
    endfunction : merge_with

    /**
     * @brief Writes the intersection of `lhs` and `rhs` into `result`.
     *
     * Only keys present in both operands are retained. The result value comes
     * from `lhs`.
     *
     * @param lhs left-hand associative-array operand.
     * @param rhs right-hand associative-array operand.
     * @param result destination associative array.
     * @post `result` keeps pre-existing keys that are not overwritten by the
     *       intersection result.
     */
    static function void intersect_into(const ref aa_t lhs,
                                        const ref aa_t rhs,
                                        ref aa_t result);
        foreach (lhs[k]) begin
            if (rhs.exists(k))
                result[k] = lhs[k];
        end
    endfunction : intersect_into

    /**
     * @brief Returns the intersection of `lhs` and `rhs`.
     *
     * @param lhs left-hand associative-array operand.
     * @param rhs right-hand associative-array operand.
     * @return a newly constructed associative array that represents the
     *         intersection result.
     */
    static function aa_t get_intersect(const ref aa_t lhs, const ref aa_t rhs);
        aa_t result;

        intersect_into(lhs, rhs, result);
        return result;
    endfunction : get_intersect

    /**
     * @brief Replaces `lhs` with the intersection of `lhs` and `rhs`.
     *
     * @param lhs destination associative array to update in place.
     * @param rhs source associative-array operand.
     */
    static function void intersect_with(ref aa_t lhs, const ref aa_t rhs);
        aa_t result;

        intersect_into(lhs, rhs, result);
        lhs = result;
    endfunction : intersect_with

    /**
     * @brief Writes the difference `lhs - rhs` into `result`.
     *
     * Keys visible only in `lhs` are retained. For a shared key, the result
     * value comes from `lhs`.
     *
     * @param lhs left-hand associative-array operand.
     * @param rhs right-hand associative-array operand.
     * @param result destination associative array.
     * @post `result` keeps pre-existing keys that are not overwritten by the
     *       difference result.
     */
    static function void diff_into(const ref aa_t lhs,
                                   const ref aa_t rhs,
                                   ref aa_t result);
        foreach (lhs[k]) begin
            if (!rhs.exists(k))
                result[k] = lhs[k];
        end
    endfunction : diff_into

    /**
     * @brief Returns the difference `lhs - rhs`.
     *
     * @param lhs left-hand associative-array operand.
     * @param rhs right-hand associative-array operand.
     * @return a newly constructed associative array that represents the
     *         difference result.
     */
    static function aa_t get_diff(const ref aa_t lhs, const ref aa_t rhs);
        aa_t result;

        diff_into(lhs, rhs, result);
        return result;
    endfunction : get_diff

    /**
     * @brief Replaces `lhs` with the difference `lhs - rhs`.
     *
     * @param lhs destination associative array to update in place.
     * @param rhs source associative-array operand.
     */
    static function void diff_with(ref aa_t lhs, const ref aa_t rhs);
        aa_t result;

        diff_into(lhs, rhs, result);
        lhs = result;
    endfunction : diff_with

    /**
     * @brief Returns the set of visible keys.
     *
     * @param a associative array to inspect.
     * @return a key set containing every visible key in `a`.
     */
    static function key_set_t get_keys(const ref aa_t a);
        key_set_t keys;

        foreach (a[k])
            void'(key_set_util::insert(keys, k));

        return keys;
    endfunction : get_keys

    /**
     * @brief Returns the flattened queue view of visible values.
     *
     * This API preserves repeated values.
     *
     * @param a associative array to inspect.
     * @return a queue containing the visible values of `a`.
     */
    static function val_q_t get_values(const ref aa_t a);
        val_q_t values;

        foreach (a[k])
            values.push_back(a[k]);

        return values;
    endfunction : get_values

    /**
     * @brief Returns a string representation of the associative array in hex
     * format.
     *
     * Each key-value pair is printed with %x formatting, one pair per line.
     *
     * @param a associative array to format.
     * @param name label printed before the entries.
     * @return a formatted string for debugging.
     */
    static function string sprint(const ref aa_t a, input string name = "aa");
        string s;
        int unsigned idx;

        if (name.len() > 0)
            s = {name, ":"};
        else
            s = "";

        idx = 0;
        foreach (a[k]) begin
            s = {s, $sformatf("\n  %0x = %0x", k, a[k])};
            idx++;
        end
        if (idx == 0)
            s = {s, " (empty)"};

        return s;
    endfunction : sprint

    /**
     * @brief Prints the string representation of the associative array in hex
     * format.
     *
     * @param a associative array to print.
     * @param name label printed before the entries.
     */
    static function void print(const ref aa_t a, input string name = "aa");
        $display("%s", sprint(a, name));
    endfunction : print
endclass : aa_util

`endif
