`ifndef __AA_UTIL_IMPL_SVH__
`define __AA_UTIL_IMPL_SVH__

static function string sprint(const ref aa_t aa, input string name);
    string s;
    int cnt = 0;

    if (aa.size() == 0)
        return $sformatf("%s = '{}  // empty, size=0", name);

    s = $sformatf("%s = '{  // size=%0d", name, aa.size());
    foreach (aa[k]) begin
        s = {s, $sformatf("\n  [%p]: %p", k, aa[k])};
        cnt++;
        if (cnt >= 100) begin
            s = {s, $sformatf("\n  ... (%0d more entries)", aa.size() - cnt)};
            break;
        end
    end

    s = {s, "\n}"};
    return s;
endfunction : sprint

static function void print(const ref aa_t aa, input string name);
    $display("%s", sprint(aa, name));
endfunction : print

static function bit equals(const ref aa_t a, const ref aa_t b);
    if (a.size() != b.size())
        return 0;

    foreach (a[k]) begin
        if (!b.exists(k))
            return 0;
        if (a[k] !== b[k])
            return 0;
    end

    return 1;
endfunction : equals

static function bit equals_verbose(
    const ref aa_t a,
    const ref aa_t b,
    input string name_a,
    input string name_b,
    output string diff
);
    int mismatch_cnt = 0;
    string s = "";

    diff = "";

    foreach (a[k]) begin
        if (!b.exists(k)) begin
            s = {s, $sformatf("\n  [%p]: only in %s = %p", k, name_a, a[k])};
            mismatch_cnt++;
        end
        else if (a[k] !== b[k]) begin
            s = {s, $sformatf("\n  [%p]: %s=%p, %s=%p", k, name_a, a[k], name_b, b[k])};
            mismatch_cnt++;
        end
    end

    foreach (b[k]) begin
        if (!a.exists(k)) begin
            s = {s, $sformatf("\n  [%p]: only in %s = %p", k, name_b, b[k])};
            mismatch_cnt++;
        end
    end

    if (mismatch_cnt > 0) begin
        diff = $sformatf("Found %0d difference(s):%s", mismatch_cnt, s);
        return 0;
    end

    return 1;
endfunction : equals_verbose

static function bit contains(const ref aa_t a, const ref aa_t b);
    foreach (b[k]) begin
        if (!a.exists(k))
            return 0;
        if (a[k] !== b[k])
            return 0;
    end

    return 1;
endfunction : contains

static function bit contains_keys(const ref aa_t a, const ref key_set_t keys);
    foreach (keys[key]) begin
        if (!a.exists(key))
            return 0;
    end

    return 1;
endfunction : contains_keys

static function bit has_key(const ref aa_t a, input KEY_T key);
    return a.exists(key);
endfunction : has_key

static function bit has_value(const ref aa_t a, input VAL_T value);
    foreach (a[k]) begin
        if (a[k] === value)
            return 1;
    end

    return 0;
endfunction : has_value

static function void merge_into(const ref aa_t lhs, const ref aa_t rhs, ref aa_t result);
    aa_t tmp;

    foreach (lhs[k])
        tmp[k] = lhs[k];

    foreach (rhs[k])
        tmp[k] = rhs[k];

    result = tmp;
endfunction : merge_into

static function aa_t get_merge(const ref aa_t lhs, const ref aa_t rhs);
    aa_t result;

    merge_into(lhs, rhs, result);
    return result;
endfunction : get_merge

static function void merge_with(ref aa_t lhs, const ref aa_t rhs);
    foreach (rhs[k])
        lhs[k] = rhs[k];
endfunction : merge_with

static function void intersect_into(const ref aa_t lhs, const ref aa_t rhs, ref aa_t result);
    aa_t tmp;

    foreach (lhs[k]) begin
        if (rhs.exists(k))
            tmp[k] = lhs[k];
    end

    result = tmp;
endfunction : intersect_into

static function aa_t get_intersect(const ref aa_t lhs, const ref aa_t rhs);
    aa_t result;

    intersect_into(lhs, rhs, result);
    return result;
endfunction : get_intersect

static function void intersect_with(ref aa_t lhs, const ref aa_t rhs);
    KEY_T keys_to_delete[$];

    foreach (lhs[k]) begin
        if (!rhs.exists(k))
            keys_to_delete.push_back(k);
    end

    foreach (keys_to_delete[i])
        lhs.delete(keys_to_delete[i]);
endfunction : intersect_with

static function aa_t get_intersect_merge_with(ref aa_t lhs, const ref aa_t rhs);
    aa_t overwritten;

    intersect_into(lhs, rhs, overwritten);
    merge_with(lhs, rhs);
    return overwritten;
endfunction : get_intersect_merge_with

static function void diff_into(const ref aa_t a, const ref aa_t b, ref aa_t result);
    aa_t tmp;

    foreach (a[k]) begin
        if (!b.exists(k))
            tmp[k] = a[k];
    end

    result = tmp;
endfunction : diff_into

static function aa_t get_diff(const ref aa_t a, const ref aa_t b);
    aa_t result;

    diff_into(a, b, result);
    return result;
endfunction : get_diff

static function void diff_with(ref aa_t lhs, const ref aa_t rhs);
    KEY_T keys_to_delete[$];

    foreach (lhs[k]) begin
        if (rhs.exists(k))
            keys_to_delete.push_back(k);
    end

    foreach (keys_to_delete[i])
        lhs.delete(keys_to_delete[i]);
endfunction : diff_with

static function key_set_t get_keys(const ref aa_t a);
    key_set_t keys;

    foreach (a[k])
        key_set_util::insert(keys, k);

    return keys;
endfunction : get_keys

static function val_set_t get_values(const ref aa_t a);
    val_set_t values;

    foreach (a[k])
        val_set_util::insert(values, a[k]);

    return values;
endfunction : get_values

`endif
