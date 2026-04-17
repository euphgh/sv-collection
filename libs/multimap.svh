`ifndef __MULTIMAP_SVH__
`define __MULTIMAP_SVH__

class multimap #(type KEY_T = logic [7:0],
                    type VAL_T = logic [31:0]);

    typedef VAL_T val_q_t[$];
    typedef val_q_t map_t[KEY_T];
    typedef multimap#(KEY_T, VAL_T) this_t;

    map_t data;

    function void clear();
        data.delete();
    endfunction

    function void add(KEY_T key, VAL_T value);
        data[key].push_back(value);
    endfunction

    function void add_values(KEY_T key, const ref val_q_t values);
        foreach (values[idx])
            data[key].push_back(values[idx]);
    endfunction

    function bit has_key(KEY_T key);
        return data.exists(key);
    endfunction

    function int unsigned num_keys();
        return data.size();
    endfunction

    function int unsigned num_values(KEY_T key);
        if (!data.exists(key))
            return 0;
        return data[key].size();
    endfunction

    function void get(KEY_T key, output val_q_t values);
        values.delete();
        if (!data.exists(key))
            return;

        foreach (data[key, idx])
            values.push_back(data[key][idx]);
    endfunction

    function void merge_from(const ref this_t rhs);
        foreach (rhs.data[key])
            foreach (rhs.data[key][idx])
                data[key].push_back(rhs.data[key][idx]);
    endfunction

    function void merge_from_aa(const ref VAL_T rhs [KEY_T]);
        foreach (rhs[key])
            data[key].push_back(rhs[key]);
    endfunction

    function this_t key_intersect(const ref this_t rhs);
        this_t result;

        result = new();
        foreach (data[key]) begin
            if (rhs.data.exists(key))
                result.add_values(key, data[key]);
        end
        return result;
    endfunction

    function bit equals(const ref this_t rhs);
        if (data.size() != rhs.data.size())
            return 0;

        foreach (data[key]) begin
            if (!rhs.data.exists(key))
                return 0;
            if (data[key].size() != rhs.data[key].size())
                return 0;
            foreach (data[key, idx]) begin
                if (data[key][idx] !== rhs.data[key][idx])
                    return 0;
            end
        end

        return 1;
    endfunction

    function string sprint(string name = "multimap");
        string s;
        int key_count;

        key_count = 0;
        s = $sformatf("%s = {", name);
        foreach (data[key]) begin
            s = {s, $sformatf("\n  [%p]: %p", key, data[key])};
            key_count++;
        end
        if (key_count == 0)
            s = {s, " // empty"};
        s = {s, "\n}"};

        return s;
    endfunction

    function void print(string name = "multimap");
        $display("%s", sprint(name));
    endfunction

endclass

`endif