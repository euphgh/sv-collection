`ifndef __AA_VALUE_ADAPTER_ARRAY_UTIL_SVH__
`define __AA_VALUE_ADAPTER_ARRAY_UTIL_SVH__

`include "aa_value_adapter_util.svh"

/**
 * @brief Provides fixed-size array-wise adapter utilities between scalar maps
 * and queue-valued multimaps.
 *
 * The container model is `aa_of_q_t aa_of_q_array_t[SIZE]` paired with
 * `aa_t aa_array_t[SIZE]`.
 * Each bank is an independent scalar-map / multimap pair.
 * Cross-type operations are applied pointwise by bank index.
 *
 * The class delegates per-bank behavior to `aa_value_adapter_util`.
 * Array-level APIs operate bank by bank and preserve unrelated content in
 * destination arrays where the delegated `aa_value_adapter_util` contract does
 * so.
 *
 * The `to_aa()` and `to_aa_of_q()` helpers project or lift each bank between
 * the two container shapes.
 *
 * @tparam SIZE fixed number of slots in the array.
 * @tparam KEY_T key type of each bank.
 * @tparam VAL_T value type stored in each bank.
 * @tparam UNIQUE_ELEM whether queue-valued operations enforce unique elements
 *                     through `aa_value_adapter_util`.
 */
class aa_value_adapter_array_util #(int unsigned SIZE = 4,
                                    type KEY_T = logic [7:0],
                                    type VAL_T = logic [31:0],
                                    bit UNIQUE_ELEM = 1);
    typedef aa_value_adapter_util#(KEY_T, VAL_T, UNIQUE_ELEM) elem_util;
    typedef elem_util::aa_of_q_t aa_of_q_t;
    typedef aa_of_q_t aa_of_q_array_t[SIZE];
    typedef elem_util::aa_t aa_t;
    typedef aa_t aa_array_t[SIZE];

    /**
     * @brief Determines whether `rhs` is contained in `lhs` bank by bank.
     *
     * @param lhs candidate superset multimap array.
     * @param rhs candidate subset scalar-map array.
     * @return `1` if every corresponding bank of `rhs` is contained in the
     *         matching bank of `lhs`; otherwise returns `0`.
     */
    // @gen
    // gen:reduce=and
    extern static function bit contains(const ref aa_of_q_array_t lhs,
                                        const ref aa_array_t rhs);

    /**
     * @brief Writes the bank-wise merge of `lhs` and `rhs` into `result`.
     *
     * Existing content in each touched bank of `result` is preserved unless the
     * delegated `aa_value_adapter_util` operation replaces it.
     *
     * @param lhs left-hand multimap array operand.
     * @param rhs right-hand scalar-map array operand.
     * @param result destination multimap array.
     */
    // @gen
    extern static function void merge_into(const ref aa_of_q_array_t lhs,
                                           const ref aa_array_t rhs,
                                           ref aa_of_q_array_t result);

    /**
     * @brief Returns the bank-wise merge of `lhs` and `rhs`.
     *
     * @param lhs left-hand multimap array operand.
     * @param rhs right-hand scalar-map array operand.
     * @return a newly constructed multimap array representing the merge result.
     */
    static function aa_of_q_array_t get_merge(const ref aa_of_q_array_t lhs,
                                              const ref aa_array_t rhs);
        aa_of_q_array_t result;

        merge_into(lhs, rhs, result);
        return result;
    endfunction : get_merge

    /**
     * @brief Merges `rhs` into `lhs` in place bank by bank.
     *
     * @param lhs destination multimap array to update in place.
     * @param rhs source scalar-map array operand.
     */
    // @gen
    extern static function void merge_with(ref aa_of_q_array_t lhs,
                                           const ref aa_array_t rhs);

    /**
     * @brief Writes the bank-wise intersection of `lhs` and `rhs` into `result`.
     *
     * Existing content in each touched bank of `result` is preserved unless the
     * delegated `aa_value_adapter_util` operation replaces it.
     *
     * @param lhs left-hand multimap array operand.
     * @param rhs right-hand scalar-map array operand.
     * @param result destination multimap array.
     */
    // @gen
    extern static function void intersect_into(const ref aa_of_q_array_t lhs,
                                               const ref aa_array_t rhs,
                                               ref aa_of_q_array_t result);

    /**
     * @brief Returns the bank-wise intersection of `lhs` and `rhs`.
     *
     * @param lhs left-hand multimap array operand.
     * @param rhs right-hand scalar-map array operand.
     * @return a newly constructed multimap array representing the intersection
     *         result.
     */
    static function aa_of_q_array_t get_intersect(const ref aa_of_q_array_t lhs,
                                                  const ref aa_array_t rhs);
        aa_of_q_array_t result;

        intersect_into(lhs, rhs, result);
        return result;
    endfunction : get_intersect

    /**
     * @brief Replaces `lhs` with the bank-wise intersection of `lhs` and `rhs`.
     *
     * @param lhs destination multimap array to update in place.
     * @param rhs source scalar-map array operand.
     */
    // @gen
    extern static function void intersect_with(ref aa_of_q_array_t lhs,
                                               const ref aa_array_t rhs);

    /**
     * @brief Writes the bank-wise difference `lhs - rhs` into `result`.
     *
     * Existing content in each touched bank of `result` is preserved unless the
     * delegated `aa_value_adapter_util` operation replaces it.
     *
     * @param lhs left-hand multimap array operand.
     * @param rhs right-hand scalar-map array operand.
     * @param result destination multimap array.
     */
    // @gen
    extern static function void diff_into(const ref aa_of_q_array_t lhs,
                                          const ref aa_array_t rhs,
                                          ref aa_of_q_array_t result);

    /**
     * @brief Returns the bank-wise difference `lhs - rhs`.
     *
     * @param lhs left-hand multimap array operand.
     * @param rhs right-hand scalar-map array operand.
     * @return a newly constructed multimap array representing the difference
     *         result.
     */
    static function aa_of_q_array_t get_diff(const ref aa_of_q_array_t lhs,
                                             const ref aa_array_t rhs);
        aa_of_q_array_t result;

        diff_into(lhs, rhs, result);
        return result;
    endfunction : get_diff

    /**
     * @brief Replaces `lhs` with the bank-wise difference `lhs - rhs`.
     *
     * @param lhs destination multimap array to update in place.
     * @param rhs source scalar-map array operand.
     */
    // @gen
    extern static function void diff_with(ref aa_of_q_array_t lhs,
                                          const ref aa_array_t rhs);

    /**
     * @brief Converts each bank from multimap to scalar map view.
     *
     * @param aa_of_q_array source multimap array.
     * @return a scalar-map array containing the first queue element per key per
     *         bank.
     */
    static function aa_array_t to_aa(const ref aa_of_q_array_t aa_of_q_array);
        aa_array_t result;

        for (int unsigned i = 0; i < SIZE; i++)
            result[i] = elem_util::to_aa(aa_of_q_array[i]);

        return result;
    endfunction : to_aa

    /**
     * @brief Lifts each bank from scalar map to multimap view.
     *
     * @param aa_array source scalar-map array.
     * @return a multimap array where each key maps to a singleton queue.
     */
    static function aa_of_q_array_t to_aa_of_q(const ref aa_array_t aa_array);
        aa_of_q_array_t result;

        for (int unsigned i = 0; i < SIZE; i++)
            result[i] = elem_util::to_aa_of_q(aa_array[i]);

        return result;
    endfunction : to_aa_of_q
endclass : aa_value_adapter_array_util

// @gen:output
`include "generated/aa_value_adapter_array_util.svh"

`endif
