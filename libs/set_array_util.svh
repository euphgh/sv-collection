`ifndef __SET_ARRAY_UTIL_SVH__
`define __SET_ARRAY_UTIL_SVH__

`include "set_util.svh"

/**
 * @brief Provides fixed-size array-wise set operations.
 *
 * The container model is `set_t set_array_t[SIZE]`.
 * Each slot is an independent set-like queue.
 * Cross-array collection operations are applied pointwise by slot index.
 *
 * The class is intended for `UNIQUE_ELEM == 1`. Array-level containment and
 * collection APIs delegate to `set_util`, so their behavior follows the
 * corresponding set contracts.
 *
 * `*_into()` has append-into-result semantics per slot. It does not clear
 * existing content in `result[i]`.
 *
 * This class intentionally exposes an array-level subset of `set_util`, not a
 * slot-local wrapper over the full queue API.
 *
 * The `sprint` / `print` helpers format one array element per output line.
 *
 * @tparam DATA_T element type stored in each slot.
 * @tparam SIZE fixed number of slots in the array.
 * @tparam UNIQUE_ELEM whether each slot behaves as a unique-element set.
 */
class set_array_util #(type DATA_T = int, int SIZE = 32, bit UNIQUE_ELEM = 1);
    typedef set_util#(DATA_T, UNIQUE_ELEM) elem_util;
    typedef elem_util::set_t set_t;
    typedef set_t set_array_t[SIZE];

    /**
     * @brief Determines whether two set arrays are semantically equal.
     *
     * Equality is defined slot by slot.
     *
     * @param lhs left-hand array operand. Must be normalized per slot.
     * @param rhs right-hand array operand. Must be normalized per slot.
     * @return `1` if every corresponding slot is equal; otherwise returns `0`.
     * @pre `UNIQUE_ELEM == 1`.
     */
    // @gen
    // gen:reduce=and
    extern static function bit equals(const ref set_array_t lhs,
                                      const ref set_array_t rhs);

    /**
     * @brief Determines whether `rhs` is contained in `lhs`.
     *
     * Containment is evaluated slot by slot.
     *
     * @param lhs candidate superset array. Must be normalized per slot.
     * @param rhs candidate subset array. Must be normalized per slot.
     * @return `1` if every slot of `rhs` is contained in the corresponding slot
     *         of `lhs`; otherwise returns `0`.
     * @pre `UNIQUE_ELEM == 1`.
     */
    // @gen
    // gen:reduce=and
    extern static function bit contains(const ref set_array_t lhs,
                                        const ref set_array_t rhs);

    /**
     * @brief Writes the slot-wise union of `lhs` and `rhs` into `result`.
     *
     * This API appends the computed union result into each `result[i]`.
     * Existing content in `result[i]` is preserved.
     *
     * @param lhs left-hand array operand. Must be normalized per slot.
     * @param rhs right-hand array operand. Must be normalized per slot.
     * @param result output array that receives the full union result.
     * @pre `UNIQUE_ELEM == 1`.
     * @post `result` retains its original content plus the union result in each
     *       slot.
     */
    // @gen
    extern static function void union_into(const ref set_array_t lhs,
                                            const ref set_array_t rhs,
                                            ref set_array_t result);

    /**
     * @brief Returns the slot-wise union of `lhs` and `rhs`.
     *
     * @param lhs left-hand array operand. Must be normalized per slot.
     * @param rhs right-hand array operand. Must be normalized per slot.
     * @return a newly constructed array that represents the union result.
     * @pre `UNIQUE_ELEM == 1`.
     */
    static function set_array_t get_union(const ref set_array_t lhs,
                                          const ref set_array_t rhs);
        set_array_t result;

        union_into(lhs, rhs, result);
        return result;
    endfunction : get_union

    /**
     * @brief Merges `rhs` into `lhs` in place.
     *
     * @param lhs destination array to update in place. Must be normalized per
     *            slot before the call.
     * @param rhs source array to merge from.
     * @pre `UNIQUE_ELEM == 1`.
     */
    // @gen
    extern static function void union_with(ref set_array_t lhs,
                                           const ref set_array_t rhs);

    /**
     * @brief Writes the slot-wise intersection of `lhs` and `rhs` into `result`.
     *
     * @param lhs left-hand array operand. Must be normalized per slot.
     * @param rhs right-hand array operand. Must be normalized per slot.
     * @param result output array that receives the full intersection result.
     * @pre `UNIQUE_ELEM == 1`.
     * @post `result` retains its original content plus the intersection result
     *       in each slot.
     */
    // @gen
    extern static function void intersect_into(const ref set_array_t lhs,
                                                const ref set_array_t rhs,
                                                ref set_array_t result);

    /**
     * @brief Returns the slot-wise intersection of `lhs` and `rhs`.
     *
     * @param lhs left-hand array operand. Must be normalized per slot.
     * @param rhs right-hand array operand. Must be normalized per slot.
     * @return a newly constructed array that represents the intersection result.
     * @pre `UNIQUE_ELEM == 1`.
     */
    static function set_array_t get_intersect(const ref set_array_t lhs,
                                              const ref set_array_t rhs);
        set_array_t result;

        intersect_into(lhs, rhs, result);
        return result;
    endfunction : get_intersect

    /**
     * @brief Replaces `lhs` with the slot-wise intersection of `lhs` and `rhs`.
     *
     * @param lhs destination array to update in place. Must be normalized per
     *            slot before the call.
     * @param rhs source array to intersect with.
     * @pre `UNIQUE_ELEM == 1`.
     */
    // @gen
    extern static function void intersect_with(ref set_array_t lhs,
                                               const ref set_array_t rhs);

    /**
     * @brief Writes the slot-wise difference `lhs - rhs` into `result`.
     *
     * @param lhs left-hand array operand. Must be normalized per slot.
     * @param rhs right-hand array operand. Must be normalized per slot.
     * @param result output array that receives the full difference result.
     * @pre `UNIQUE_ELEM == 1`.
     * @post `result` retains its original content plus the difference result in
     *       each slot.
     */
    // @gen
    extern static function void diff_into(const ref set_array_t lhs,
                                           const ref set_array_t rhs,
                                           ref set_array_t result);

    /**
     * @brief Returns the slot-wise difference `lhs - rhs`.
     *
     * @param lhs left-hand array operand. Must be normalized per slot.
     * @param rhs right-hand array operand. Must be normalized per slot.
     * @return a newly constructed array that represents the difference result.
     * @pre `UNIQUE_ELEM == 1`.
     */
    static function set_array_t get_diff(const ref set_array_t lhs,
                                         const ref set_array_t rhs);
        set_array_t result;

        diff_into(lhs, rhs, result);
        return result;
    endfunction : get_diff

    /**
     * @brief Replaces `lhs` with the slot-wise difference `lhs - rhs`.
     *
     * @param lhs destination array to update in place. Must be normalized per
     *            slot before the call.
     * @param rhs source array to subtract.
     * @pre `UNIQUE_ELEM == 1`.
     */
    // @gen
    extern static function void diff_with(ref set_array_t lhs,
                                          const ref set_array_t rhs);

    /**
     * @brief Returns a row-based string representation of the array.
     *
     * Each output line corresponds to one array element.
     *
     * @param array array to format.
     * @param name label printed before the rows.
     * @return a formatted string for debugging.
     * @pre `UNIQUE_ELEM == 1`.
     */
    static function string sprint(const ref set_array_t array,
                                 input string name = "bank_mem");
        string s;

        s = {name, "\n"};

        foreach (array[i]) begin
            s = {s, $sformatf("[%0d]: %p", i, array[i])};
            if (i != SIZE - 1)
                s = {s, "\n"};
        end

        return s;
    endfunction : sprint

    /**
     * @brief Prints the row-based string representation of the array.
     *
     * @param array array to print.
     * @param name label printed before the rows.
     * @pre `UNIQUE_ELEM == 1`.
     */
    static function void print(const ref set_array_t array,
                              input string name = "bank_mem");
        $display("%s", sprint(array, name));
    endfunction : print
endclass : set_array_util

// @gen:output
`include "generated/set_array_util.svh"

`endif
