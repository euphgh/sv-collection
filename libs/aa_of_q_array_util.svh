`ifndef __AA_OF_Q_ARRAY_UTIL_SVH__
`define __AA_OF_Q_ARRAY_UTIL_SVH__

`include "aa_of_q_util.svh"

/**
 * @brief Provides fixed-size array-wise multimap utilities.
 *
 * The container model is `aa_of_q_t aa_of_q_array_t[SIZE]`.
 * Each slot is an independent multimap.
 * Cross-array collection operations are applied pointwise by slot index.
 *
 * The class delegates per-slot behavior to `aa_of_q_util`.
 * Array-level collection APIs operate bank by bank and preserve unrelated
 * content in destination arrays where the delegated `aa_of_q_util` contract
 * does so.
 *
 * The `clean()` helper normalizes each bank in place.
 * The `get_keys()` and `get_value_sets()` helpers project each bank into
 * a corresponding set container.
 * The `sprint` / `print` helpers format one array element per output line.
 *
 * @tparam SIZE fixed number of slots in the array.
 * @tparam KEY_T key type of each multimap bank.
 * @tparam VAL_T value type stored in each value queue.
 * @tparam UNIQUE_ELEM whether each value queue enforces unique elements
 *                     through `aa_of_q_util`.
 */
class aa_of_q_array_util #(int unsigned SIZE = 4,
                           type KEY_T = logic [7:0],
                           type VAL_T = logic [31:0],
                           bit UNIQUE_ELEM = 1);
    typedef aa_of_q_util#(KEY_T, VAL_T, UNIQUE_ELEM) elem_util;
    typedef elem_util::aa_of_q_t aa_of_q_t;
    typedef aa_of_q_t aa_of_q_array_t[SIZE];
    typedef elem_util::key_set_t key_set_t;
    typedef key_set_t key_set_array_t[SIZE];
    typedef elem_util::val_set_t val_set_t;
    typedef val_set_t val_set_array_t[SIZE];

    /**
     * @brief Determines whether two array-of-multimap values are equal.
     *
     * Equality is defined bank by bank.
     *
     * @param lhs left-hand array operand.
     * @param rhs right-hand array operand.
     * @return `1` if every corresponding bank is equal; otherwise returns `0`.
     */
    // @gen
    // gen:reduce=and
    extern static function bit equals(const ref aa_of_q_array_t lhs,
                                      const ref aa_of_q_array_t rhs);

    /**
     * @brief Determines whether `rhs` is contained in `lhs` bank by bank.
     *
     * @param lhs candidate superset array.
     * @param rhs candidate subset array.
     * @return `1` if every corresponding bank of `rhs` is contained in the
     *         matching bank of `lhs`; otherwise returns `0`.
     */
    // @gen
    // gen:reduce=and
    extern static function bit contains(const ref aa_of_q_array_t lhs,
                                        const ref aa_of_q_array_t rhs);

    /**
     * @brief Writes the bank-wise merge of `lhs` and `rhs` into `result`.
     *
     * Existing content in each touched bank of `result` is preserved unless the
     * delegated `aa_of_q_util` operation replaces it.
     *
     * @param lhs left-hand array operand.
     * @param rhs right-hand array operand.
     * @param result destination array.
     */
    // @gen
    extern static function void merge_into(const ref aa_of_q_array_t lhs,
                                           const ref aa_of_q_array_t rhs,
                                           ref aa_of_q_array_t result);

    /**
     * @brief Returns the bank-wise merge of `lhs` and `rhs`.
     *
     * @param lhs left-hand array operand.
     * @param rhs right-hand array operand.
     * @return a newly constructed array representing the merge result.
     */
    static function aa_of_q_array_t get_merge(const ref aa_of_q_array_t lhs,
                                              const ref aa_of_q_array_t rhs);
        aa_of_q_array_t result;

        merge_into(lhs, rhs, result);
        return result;
    endfunction : get_merge

    /**
     * @brief Merges `rhs` into `lhs` in place bank by bank.
     *
     * @param lhs destination array to update in place.
     * @param rhs source array to merge from.
     */
    // @gen
    extern static function void merge_with(ref aa_of_q_array_t lhs,
                                           const ref aa_of_q_array_t rhs);

    /**
     * @brief Writes the bank-wise intersection of `lhs` and `rhs` into `result`.
     *
     * Existing content in each touched bank of `result` is preserved unless the
     * delegated `aa_of_q_util` operation replaces it.
     *
     * @param lhs left-hand array operand.
     * @param rhs right-hand array operand.
     * @param result destination array.
     */
    // @gen
    extern static function void intersect_into(const ref aa_of_q_array_t lhs,
                                               const ref aa_of_q_array_t rhs,
                                               ref aa_of_q_array_t result);

    /**
     * @brief Returns the bank-wise intersection of `lhs` and `rhs`.
     *
     * @param lhs left-hand array operand.
     * @param rhs right-hand array operand.
     * @return a newly constructed array representing the intersection result.
     */
    static function aa_of_q_array_t get_intersect(const ref aa_of_q_array_t lhs,
                                                  const ref aa_of_q_array_t rhs);
        aa_of_q_array_t result;

        intersect_into(lhs, rhs, result);
        return result;
    endfunction : get_intersect

    /**
     * @brief Replaces `lhs` with the bank-wise intersection of `lhs` and `rhs`.
     *
     * @param lhs destination array to update in place.
     * @param rhs source array to intersect with.
     */
    // @gen
    extern static function void intersect_with(ref aa_of_q_array_t lhs,
                                               const ref aa_of_q_array_t rhs);

    /**
     * @brief Writes the bank-wise difference `lhs - rhs` into `result`.
     *
     * Existing content in each touched bank of `result` is preserved unless the
     * delegated `aa_of_q_util` operation replaces it.
     *
     * @param lhs left-hand array operand.
     * @param rhs right-hand array operand.
     * @param result destination array.
     */
    // @gen
    extern static function void diff_into(const ref aa_of_q_array_t lhs,
                                          const ref aa_of_q_array_t rhs,
                                          ref aa_of_q_array_t result);

    /**
     * @brief Returns the bank-wise difference `lhs - rhs`.
     *
     * @param lhs left-hand array operand.
     * @param rhs right-hand array operand.
     * @return a newly constructed array representing the difference result.
     */
    static function aa_of_q_array_t get_diff(const ref aa_of_q_array_t lhs,
                                             const ref aa_of_q_array_t rhs);
        aa_of_q_array_t result;

        diff_into(lhs, rhs, result);
        return result;
    endfunction : get_diff

    /**
     * @brief Replaces `lhs` with the bank-wise difference `lhs - rhs`.
     *
     * @param lhs destination array to update in place.
     * @param rhs source array to subtract.
     */
    // @gen
    extern static function void diff_with(ref aa_of_q_array_t lhs,
                                          const ref aa_of_q_array_t rhs);

    /**
     * @brief Normalizes every bank in the array in place.
     *
     * @param a array to normalize.
     * @post every bank in `a` satisfies the normalized `aa_of_q_t` invariant.
     */
    // @gen
    extern static function void clean(ref aa_of_q_array_t a);

    /**
     * @brief Returns the key set for every bank.
     *
     * @param aa_of_q_array array to inspect.
     * @return an array of per-bank key sets.
     */
    static function key_set_array_t get_keys(const ref aa_of_q_array_t aa_of_q_array);
        key_set_array_t result;

        for (int unsigned i = 0; i < SIZE; i++)
            result[i] = elem_util::get_keys(aa_of_q_array[i]);

        return result;
    endfunction : get_keys

    /**
     * @brief Returns the value set for every bank.
     *
     * @param aa_of_q_array array to inspect.
     * @return an array of per-bank flattened value sets.
     */
    static function val_set_array_t get_value_sets(const ref aa_of_q_array_t aa_of_q_array);
        val_set_array_t result;

        for (int unsigned i = 0; i < SIZE; i++)
            result[i] = elem_util::get_values(aa_of_q_array[i]);

        return result;
    endfunction : get_value_sets

    /**
     * @brief Returns a row-based string representation of the array.
     *
     * Each output line corresponds to one array element.
     *
     * @param aa_of_q_array array to format.
     * @param name label printed before the rows.
     * @return a formatted string for debugging.
     */
    static function string sprint(const ref aa_of_q_array_t aa_of_q_array,
                                  input string name = "bank_mem");
        string s;

        s = {name, "\n"};

        foreach (aa_of_q_array[i]) begin
            s = {s, $sformatf("[%0d]: %p", i, aa_of_q_array[i])};
            if (i != SIZE - 1)
                s = {s, "\n"};
        end

        return s;
    endfunction : sprint

    /**
     * @brief Prints the row-based string representation of the array.
     *
     * @param aa_of_q_array array to print.
     * @param name label printed before the rows.
     */
    static function void print(const ref aa_of_q_array_t aa_of_q_array,
                               input string name = "bank_mem");
        $display("%s", sprint(aa_of_q_array, name));
    endfunction : print
endclass : aa_of_q_array_util

// @gen:output
`include "generated/aa_of_q_array_util.svh"

`endif
