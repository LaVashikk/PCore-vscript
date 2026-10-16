/*
 * ArrayEx: a wrapper around a native array with chainable methods.
*/
::ArrayEx <- class {
    // The internal array. 
    arr = null

    /*
     * Creates an ArrayEx that holds the given values.
     *
     * @param {...} ... - A variable number of arguments representing the initial elements of the array.
    */
    constructor(...) {
        this.arr = array(vargc);

        for(local i = 0; i < vargc; i++) {
            this.arr[i] = vargv[i]
        }
    }

    /*
     * Wraps a native array in a new ArrayEx without copying it.
     *
     * If the input array is already an ArrayEx object, it is returned directly.
     *
     * @param {array} array - The initial array to use for the ArrayEx object.
     * @returns {ArrayEx} - The newly created or the input ArrayEx object.
    */
    function FromArray(array) {
        // if it's already an ArrayEx, just return it.
        if(typeof array == "ArrayEx")
            return array
        
        if(typeof array != "array") throw("ArrayEx.FromArray: Invalid argument. This function only accepts a standard 'array' for conversion. Got type '" + typeof array + "' instead.")

        local arrayEx = ArrayEx()
        arrayEx.arr = array
        return arrayEx
    }

    /*
     * Creates a new ArrayEx object with a specified size, optionally filled with a default value.
     *
     * @param {int} numberOfItems - The desired number of elements in the array.
     * @param {any} fillValue - The value to fill the array with (defaults to null).
     * @returns {ArrayEx} - The newly created ArrayEx object.
    */
    function WithSize(numberOfItems, fillValue = null) {
        return ArrayEx.FromArray(array(numberOfItems, fillValue))
    } 

    /*
     * Append a value to the array.
     * 
     * @param {any} val - The value to append.
     * @returns {ArrayEx} - The ArrayEx instance for chaining.
    */
    function append(val) {
        arr.append(val);
        return this
    }

    /*
     * Apply a function to each element and modify the array in-place.
     * 
     * @param {Function} func - The function to apply.
     * @returns {ArrayEx} - The ArrayEx instance for chaining.
    */
    function apply(func) {
        foreach(idx, value in arr) {
            arr[idx] = func(value, idx)
        }
        return this
    }

    /*
     * Clear the array.
     * 
     * @returns {ArrayEx} - The ArrayEx instance for chaining.
    */
    function clear() {
        this.arr.clear()
        return this
    }

    /*
     * Extend the array with another array.
     * 
     * @param {array|ArrayEx} other - The array to extend from.
     * @returns {ArrayEx} - The ArrayEx instance for chaining.
    */
    function extend(other) {
        if(typeof other == "ArrayEx") {
            other = other.arr
        }

        arr.extend(other);
        return this
    }

    /*
     * Filter the array by a predicate function.
     * 
     * @param {Function} condition(index, value, newArray) - The predicate function. 
     * @returns {ArrayEx} - The filtered array.
    */
    function filter(condition) {
        local newArray = ArrayEx()
        foreach(idx, val in arr) {
            if(condition(idx, val, newArray))
                newArray.append(val)
        }
        return newArray
    }

    /*
     * Check if the array contains a value, compared with ==. A linear search: for many lookups, use a table.
     * 
     * @param {any} match - The value to find.
     * @returns {boolean} - Whether the value is found.
    */
    function contains(match) {
        foreach(val in this.arr)
            if(val == match) return true
        return false
    }

    /*
     * Search for a value in the array.
     * 
     * @param {any|Function} match - The value or predicate to search for.
     * @returns {int|null} - The index of the match or null.
    */
    function search(match) {
        if(typeof match == "function") {
            foreach(idx, val in this.arr) {
                if(match(val))
                    return idx
            }
        }
        else {
            foreach(idx, val in this.arr) {
                if(val == match)
                    return idx
            }
        }

        return null
    }

    /*
     * Insert a value into the array.
     * 
     * @param {int} idx - The index to insert at.
     * @param {any} val - The value to insert.
     * @returns {ArrayEx} - The ArrayEx instance for chaining.
    */
    function insert(idx, val) {
        arr.insert(idx, val)
        return this
    }

    /*
     * Get the array length.
     * 
     * @returns {int} - The array length.
    */
    function len() {
        return this.arr.len()
    }

    /*
     * Map the array to a new array via a function.
     * 
     * @param {Function} func - The mapping function.
     * @returns {ArrayEx} - The mapped array.
    */
    function map(func) {
        if(typeof func != "function") throw("ArrayEx.map: The 'func' argument must be a function, but got " + typeof func);
        local newArray = array(this.len())
        foreach(idx, value in arr) {
            newArray[idx] = func(value, idx)
        }
        return ArrayEx.FromArray(newArray)
    }

    /*
     * Reduce the array to a single value.
     * 
     * @param {Function} func - The reducer function, which takes the accumulator and current item as arguments.
     * @param {any} initial - The initial value of the accumulator.
     * @returns {any} - The reduced value.
    */
    function reduce(func, initial) {
        local accumulator = initial
        foreach(item in arr) {
            accumulator = func(accumulator, item)
        }
        return accumulator
    }

    /*
     * Return a new array without duplicates, keeping the first occurrence. Values are compared as table keys:
     * numbers and strings by value, instances, tables and arrays by identity.
     * 
     * @returns {ArrayEx} - The new array with unique elements.
    */
    function unique() {
        local seen = {}
        local seenNull = false
        local result = ArrayEx()

        foreach(value in this.arr) {
            // null can't be a table key
            if(value == null) {
                if(seenNull) continue
                seenNull = true
            }
            else {
                if(value in seen) continue
                seen[value] <- true
            }
            result.arr.append(value)
        }

        return result
    }

    /*
     * Pop a value off the end of the array.
     * 
     * @returns {any} - The popped value.
    */
    function pop() {
        return arr.pop()
    }

    /*
     * Append a value to the array.
     * 
     * @param {any} val - The value to append.
     * @returns {ArrayEx} - The ArrayEx instance for chaining.
    */
    function push(val) {
        this.append(val)
        return this
    }

    /*
     * Remove an element by index.
     * 
     * @param {int} idx - The index to remove.
     * @returns {any} - The value of the removed element.
    */
    function remove(idx) {
        return arr.remove(idx)
    }

    /*
     * Resize the array.
     * 
     * @param {int} size - The new size.
     * @param {any} fill - The fill value for new slots.
    */
    function resize(size, fill = null) {
        arr.resize(size, fill);
        return this
    }

    /*
     * Reverse the array in-place.
     * 
     * @returns {ArrayEx} - The reversed array.
    */
    function reverse() {
        arr.reverse();
        return this
    }

    /*
     * Slice a portion of the array.
     * 
     * @param {int} startIndex - The start index.
     * @param {int} endIndex - The end index. (optional)
     * @returns {ArrayEx} - The sliced array.
    */
    function slice(startIndex, endIndex = null) {
        return ArrayEx.FromArray(arr.slice(startIndex, endIndex || this.len()))
    }

    /*
     * Sort the array.
     * 
     * @param {Function} func - Optional compare function.
     * @returns {ArrayEx} - The sorted array.
    */
    function sort(func = null) {
        func ? arr.sort(func) : arr.sort()
        return this
    }

    /*
     * Get the last element.
     * 
     * @returns {any} - The last element.
    */
    function top() {
        return arr.top();
    }

    /*
     * Join the array into a string.
     * 
     * @param {string} joinstr - The separator string.
     * @returns {string} - The joined string.
    */
    function join(joinstr = "") {
        if(this.len() == 0) return ""
        
        local string = ""
        foreach(elem in this.arr) {
            string += elem + joinstr
        }
        return joinstr.len() != 0 ? string.slice(0, joinstr.len() * -1) : string
    }

    /*
     * Retrieve the element at the specified index in the array.
     * 
     * @param {integer} idx - The index of the element to retrieve.
     * @param {any} defaultVal - Optional default value to return if the index is out of bounds. Defaults to null.
     * @returns {any} - The element at the specified index or the default value if the index is out of bounds.
    */
    function get(idx, defaultVal = null) {
        if(this.len() > idx)
            return this.arr[idx]
        return defaultVal
    }

    /*
     * Convert the array to a new table with the elements as keys (null values). null elements are skipped.
     * 
     * @returns {table} - The table.
    */
    function totable() {
        local table = {}
        foreach(element in arr) {
            // null can't be the key
            if(element != null) table[element] <- null
        }
        return table
    }

    /*
     * Converts the array to a List.
     *
     * @returns {List} - A new List with the same elements.
    */
    function tolist() {
        local list = List()
        foreach(idx, value in this.arr) {
            list.append(value)
        }
        return list
    }

    /*
     * Creates a new ArrayEx with a shallow copy of the array.
     *
     * @returns {ArrayEx} - The copy.
    */
    function Clone() {
        return ArrayEx.FromArray(clone this.arr)
    }

    /*
     * Convert the array to a string.
     * 
     * @returns {string} - The string representation.
    */
    function _tostring() return format("Array: [%s]", this.join(", "))
    
    function _typeof () return "ArrayEx";
    function _get(idx) return arr[idx];
    function _set(idx, val) return arr[idx] = val;
    // Squirrel calls it on the new instance, which shares `arr` with the original until here
    function _cloned(original) this.arr = clone original.arr
    function _nexti(previdx) {
        if(this.arr.len() == 0) return null
        if (previdx == null) return 0;
		return previdx < this.arr.len() - 1 ? previdx + 1 : null;
	}
}