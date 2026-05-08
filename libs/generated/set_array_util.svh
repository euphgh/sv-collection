// This file is generated. The class and contracts live in
// `libs/set_array_util.svh`.

function bit set_array_util::equals(
    const ref set_array_t lhs,
    const ref set_array_t rhs
);
    for (int i = 0; i < SIZE; i++) begin
        if (!set_elem_util_t::equals(lhs[i], rhs[i]))
            return 0;
    end

    return 1;
endfunction : equals

function bit set_array_util::contains(
    const ref set_array_t lhs,
    const ref set_array_t rhs
);
    foreach (rhs[i]) begin
        if (!set_elem_util_t::contains(lhs[i], rhs[i]))
            return 0;
    end

    return 1;
endfunction : contains

function void set_array_util::union_into(
    const ref set_array_t lhs,
    const ref set_array_t rhs,
    ref set_array_t result
);
    for (int i = 0; i < SIZE; i++)
        set_elem_util_t::union_into(lhs[i], rhs[i], result[i]);
endfunction : union_into

function void set_array_util::union_with(
    ref set_array_t lhs,
    const ref set_array_t rhs
);
    for (int i = 0; i < SIZE; i++)
        set_elem_util_t::union_with(lhs[i], rhs[i]);
endfunction : union_with

function void set_array_util::intersect_into(
    const ref set_array_t lhs,
    const ref set_array_t rhs,
    ref set_array_t result
);
    for (int i = 0; i < SIZE; i++)
        set_elem_util_t::intersect_into(lhs[i], rhs[i], result[i]);
endfunction : intersect_into

function void set_array_util::intersect_with(
    ref set_array_t lhs,
    const ref set_array_t rhs
);
    for (int i = 0; i < SIZE; i++)
        set_elem_util_t::intersect_with(lhs[i], rhs[i]);
endfunction : intersect_with

function void set_array_util::diff_into(
    const ref set_array_t lhs,
    const ref set_array_t rhs,
    ref set_array_t result
);
    for (int i = 0; i < SIZE; i++)
        set_elem_util_t::diff_into(lhs[i], rhs[i], result[i]);
endfunction : diff_into

function void set_array_util::diff_with(
    ref set_array_t lhs,
    const ref set_array_t rhs
);
    for (int i = 0; i < SIZE; i++)
        set_elem_util_t::diff_with(lhs[i], rhs[i]);
endfunction : diff_with
