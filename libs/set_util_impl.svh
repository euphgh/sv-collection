`ifndef __SET_UTIL_IMPL_SVH__
`define __SET_UTIL_IMPL_SVH__

static function void insert(ref set_t set, input KEY_T key);
    set[key] = 1'b1;
endfunction : insert

static function void delete(ref set_t set, input KEY_T key);
    set.delete(key);
endfunction : delete

static function bit contains_key(const ref set_t set, input KEY_T key);
    return set.exists(key);
endfunction : contains_key

static function bit contains_set(const ref set_t lhs, const ref set_t rhs);
    foreach (rhs[key]) begin
        if (!lhs.exists(key))
            return 0;
    end

    return 1;
endfunction : contains_set

static function q_of_data to_queue(const ref set_t lhs);
    q_of_data result;

    result.delete();
    foreach (lhs[key])
        result.push_back(key);

    return result;
endfunction : to_queue

static function aa_of_data to_aa(const ref set_t lhs);
    return lhs;
endfunction : to_aa

static function void union_into(const ref set_t lhs, const ref set_t rhs, ref set_t result);
    foreach (lhs[key])
        result[key] = 1'b1;

    foreach (rhs[key])
        result[key] = 1'b1;
endfunction : union_into

static function set_t get_union(const ref set_t lhs, const ref set_t rhs);
    set_t result;

    union_into(lhs, rhs, result);
    return result;
endfunction : get_union

static function void union_with(ref set_t lhs, const ref set_t rhs);
    foreach (rhs[key])
        lhs[key] = 1'b1;
endfunction : union_with

static function void intersect_into(const ref set_t lhs, const ref set_t rhs, ref set_t result);
    foreach (lhs[key]) begin
        if (rhs.exists(key))
            result[key] = 1'b1;
    end
endfunction : intersect_into

static function set_t get_intersect(const ref set_t lhs, const ref set_t rhs);
    set_t result;

    intersect_into(lhs, rhs, result);
    return result;
endfunction : get_intersect

static function void intersect_with(ref set_t lhs, const ref set_t rhs);
    q_of_data keys_to_delete;

    foreach (lhs[key]) begin
        if (!rhs.exists(key))
            keys_to_delete.push_back(key);
    end

    foreach (keys_to_delete[i])
        lhs.delete(keys_to_delete[i]);
endfunction : intersect_with

static function void diff_into(const ref set_t lhs, const ref set_t rhs, ref set_t result);
    foreach (lhs[key]) begin
        if (!rhs.exists(key))
            result[key] = 1'b1;
    end
endfunction : diff_into

static function set_t get_diff(const ref set_t lhs, const ref set_t rhs);
    set_t result;

    diff_into(lhs, rhs, result);
    return result;
endfunction : get_diff

static function void diff_with(ref set_t lhs, const ref set_t rhs);
    q_of_data keys_to_delete;

    foreach (lhs[key]) begin
        if (rhs.exists(key))
            keys_to_delete.push_back(key);
    end

    foreach (keys_to_delete[i])
        lhs.delete(keys_to_delete[i]);
endfunction : diff_with

`endif
