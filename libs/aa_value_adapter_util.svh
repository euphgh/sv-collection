`ifndef __AA_VALUE_ADAPTER_UTIL_SVH__
`define __AA_VALUE_ADAPTER_UTIL_SVH__

`include "aa_of_q_util.svh"

/**
 * @brief Adapts `aa_t` values to and from queue-valued `aa_of_q_t` entries.
 *
 * This helper bridges the repository's scalar map view and queue-valued
 * multimap view by treating each scalar value as a singleton queue under the
 * same key.
 *
 * Queue behavior delegates to `set_util`, and multimap behavior delegates to
 * `aa_of_q_util`.
 *
 * @tparam KEY_T key type of the associative array. It is expected to be a
 *               hashable 2-state type.
 * @tparam VAL_T value type stored in the scalar map and queue entries. It is
 *               expected to be a 2-state type comparable with `==`.
 * @tparam UNIQUE_ELEM whether queue-valued operations enforce unique elements
 *                     through `set_util`. The default value is `1`.
 */
class aa_value_adapter_util #(type KEY_T = int, type VAL_T = real, bit UNIQUE_ELEM = 1);
    typedef VAL_T val_t;
    typedef set_util#(VAL_T, UNIQUE_ELEM) val_set_util;
    typedef val_set_util::set_t val_q_t;

    typedef aa_util#(KEY_T, val_t) aa_util_t;
    typedef aa_util_t::aa_t aa_t;

    typedef aa_of_q_util#(KEY_T, val_t, UNIQUE_ELEM) aa_of_q_util_t;
    typedef aa_of_q_util_t::aa_of_q_t aa_of_q_t;

    // ---------------------------------------------------------------------
    // Public API
    // ---------------------------------------------------------------------

    /**
     * @brief Determines whether `rhs` is contained in `lhs`.
     *
     * Containment is evaluated key by key. A key visible in `rhs` must also be
     * visible in `lhs`, and the scalar value for that key must appear in the
     * corresponding queue of `lhs`.
     *
     * @param lhs candidate superset multimap. Must be normalized.
     * @param rhs candidate subset scalar map.
     * @return `1` if every visible key and scalar value in `rhs` is contained
     *         in `lhs`; otherwise returns `0`.
     * @pre `lhs` does not contain keys mapped to empty queues.
     */
    static function bit contains(const ref aa_of_q_t lhs, const ref aa_t rhs);
        foreach (rhs[key]) begin
            if (!lhs.exists(key))
                return 0;
            if (val_set_util::count(lhs[key], rhs[key]) == 0)
                return 0;
        end

        return 1;
    endfunction : contains

    /**
     * @brief Writes the merge of `lhs` and `rhs` into `result`.
     *
     * The result keeps the union of visible keys. This API updates `result` in
     * place and preserves unrelated existing content. For a touched key, the
     * queue stored at `result[key]` is replaced with the merged queue.
     *
     * @param lhs left-hand multimap operand. Must be normalized.
     * @param rhs right-hand scalar-map operand.
     * @param result destination multimap to update in place.
     * @pre `lhs` does not contain keys mapped to empty queues.
     * @post `result` remains normalized for the keys this API updates.
     */
    static function void merge_into(const ref aa_of_q_t lhs,
                                    const ref aa_t rhs,
                                    ref aa_of_q_t result);
        val_q_t queue;

        foreach (lhs[key])
            result[key] = lhs[key];

        foreach (rhs[key]) begin
            if (result.exists(key))
                queue = result[key];
            else
                queue = lhs.exists(key) ? lhs[key] : {};

            void'(val_set_util::insert(queue, rhs[key]));
            result[key] = queue;
        end
    endfunction : merge_into

    /**
     * @brief Returns the merge of `lhs` and `rhs`.
     *
     * @param lhs left-hand multimap operand. Must be normalized.
     * @param rhs right-hand scalar-map operand.
     * @return a newly constructed normalized multimap that represents the merge
     *         result.
     * @pre `lhs` does not contain keys mapped to empty queues.
     */
    static function aa_of_q_t get_merge(const ref aa_of_q_t lhs,
                                       const ref aa_t rhs);
        aa_of_q_t result;

        result.delete();
        merge_into(lhs, rhs, result);
        return result;
    endfunction : get_merge

    /**
     * @brief Merges `rhs` into `lhs` in place.
     *
     * @param lhs destination multimap to update in place. Must be normalized
     *            before the call.
     * @param rhs source scalar-map operand.
     * @pre `lhs` does not contain keys mapped to empty queues.
     * @post `lhs` remains normalized.
     */
    static function void merge_with(ref aa_of_q_t lhs, const ref aa_t rhs);
        aa_of_q_t tmp;

        tmp.delete();
        merge_into(lhs, rhs, tmp);
        lhs = tmp;
    endfunction : merge_with

    /**
     * @brief Writes the intersection of `lhs` and `rhs` into `result`.
     *
     * Only keys that appear in both operands may be retained. For a shared key,
     * the queue stored at `result[key]` is replaced with a singleton queue
     * containing `rhs[key]` when the value is present in `lhs[key]`. If the
     * resulting queue would be empty, the existing content at `result[key]` is
     * left unchanged.
     *
     * @param lhs left-hand multimap operand. Must be normalized.
     * @param rhs right-hand scalar-map operand.
     * @param result destination multimap to update in place.
     * @pre `lhs` does not contain keys mapped to empty queues.
     * @post `result` remains normalized for the keys this API updates.
     */
    static function void intersect_into(const ref aa_of_q_t lhs,
                                        const ref aa_t rhs,
                                        ref aa_of_q_t result);
        foreach (lhs[key]) begin
            if (!rhs.exists(key))
                continue;
            if (val_set_util::count(lhs[key], rhs[key]) == 0)
                continue;

            result[key] = {rhs[key]};
        end
    endfunction : intersect_into

    /**
     * @brief Returns the intersection of `lhs` and `rhs`.
     *
     * @param lhs left-hand multimap operand. Must be normalized.
     * @param rhs right-hand scalar-map operand.
     * @return a newly constructed normalized multimap that represents the
     *         intersection result.
     * @pre `lhs` does not contain keys mapped to empty queues.
     */
    static function aa_of_q_t get_intersect(const ref aa_of_q_t lhs,
                                            const ref aa_t rhs);
        aa_of_q_t result;

        result.delete();
        intersect_into(lhs, rhs, result);
        return result;
    endfunction : get_intersect

    /**
     * @brief Replaces `lhs` with the intersection of `lhs` and `rhs`.
     *
     * @param lhs destination multimap to update in place. Must be normalized
     *            before the call.
     * @param rhs source scalar-map operand.
     * @pre `lhs` does not contain keys mapped to empty queues.
     * @post `lhs` remains normalized.
     */
    static function void intersect_with(ref aa_of_q_t lhs, const ref aa_t rhs);
        aa_of_q_t tmp;

        tmp.delete();
        intersect_into(lhs, rhs, tmp);
        lhs = tmp;
    endfunction : intersect_with

    /**
     * @brief Writes the difference `lhs - rhs` into `result`.
     *
     * Keys visible only in `lhs` are retained. For shared keys, one occurrence
     * of `rhs[key]` is removed from the corresponding queue and the queue stored
     * at `result[key]` is replaced with the new queue. If the resulting queue is
     * empty, the existing content at `result[key]` is left unchanged.
     *
     * @param lhs left-hand multimap operand. Must be normalized.
     * @param rhs right-hand scalar-map operand.
     * @param result destination multimap to update in place.
     * @pre `lhs` does not contain keys mapped to empty queues.
     * @post `result` remains normalized for the keys this API updates.
     */
    static function void diff_into(const ref aa_of_q_t lhs,
                                   const ref aa_t rhs,
                                   ref aa_of_q_t result);
        val_q_t queue;

        foreach (lhs[key]) begin
            queue = lhs[key];

            if (rhs.exists(key))
                val_set_util::delete(queue, rhs[key]);

            if (queue.size() != 0)
                result[key] = queue;
        end
    endfunction : diff_into

    /**
     * @brief Returns the difference `lhs - rhs`.
     *
     * @param lhs left-hand multimap operand. Must be normalized.
     * @param rhs right-hand scalar-map operand.
     * @return a newly constructed normalized multimap that represents the
     *         difference result.
     * @pre `lhs` does not contain keys mapped to empty queues.
     */
    static function aa_of_q_t get_diff(const ref aa_of_q_t lhs,
                                       const ref aa_t rhs);
        aa_of_q_t result;

        result.delete();
        diff_into(lhs, rhs, result);
        return result;
    endfunction : get_diff

    /**
     * @brief Replaces `lhs` with the difference `lhs - rhs`.
     *
     * @param lhs destination multimap to update in place. Must be normalized
     *            before the call.
     * @param rhs source scalar-map operand.
     * @pre `lhs` does not contain keys mapped to empty queues.
     * @post `lhs` remains normalized.
     */
    static function void diff_with(ref aa_of_q_t lhs, const ref aa_t rhs);
        aa_of_q_t tmp;

        tmp.delete();
        diff_into(lhs, rhs, tmp);
        lhs = tmp;
    endfunction : diff_with

    /**
     * @brief Converts a normalized multimap into a scalar map view.
     *
     * The caller must ensure each visible key maps to a singleton queue.
     *
     * @param aa_of_q source multimap to project.
     * @return a scalar map containing the first queue element for each key.
     * @pre `aa_of_q` does not contain keys mapped to empty queues.
     * @pre each visible queue in `aa_of_q` contains exactly one element.
     */
    static function aa_t to_aa(const ref aa_of_q_t aa_of_q);
        aa_t res;

        foreach (aa_of_q[key]) begin
            if (aa_of_q[key].size() > 0)
                res[key] = aa_of_q[key][0];
        end

        return res;
    endfunction : to_aa

    /**
     * @brief Converts a scalar map into a normalized multimap view.
     *
     * Each scalar value becomes a singleton queue under the same key.
     *
     * @param aa source scalar map to lift.
     * @return a normalized multimap where each key maps to a singleton queue.
     */
    static function aa_of_q_t to_aa_of_q(const ref aa_t aa);
        aa_of_q_t res;

        foreach (aa[key]) begin
            res[key] = {aa[key]};
        end

        return res;
    endfunction : to_aa_of_q
endclass : aa_value_adapter_util

`endif
