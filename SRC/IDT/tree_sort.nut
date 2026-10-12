/*
 * A node in an AVL tree.
*/
::treeNode <- class {
    value = null;
    // The left child node. 
    l = null;
    // The right child node. 
    r = null; 
    // The height of the subtree rooted at this node (1 for a leaf).
    h = 1; 

    /*
     * Constructor for a tree node.
     *
     * @param {any} value - The value to store in the node.
    */
    constructor(value) {
        this.value = value;
    }

    function _tostring() return format("treeNode(%i)", this.value);
    
    function _typeof() return "treeNode"
}

/*
 * A self-balancing (AVL) binary search tree of mutually comparable values. Duplicates are allowed.
 * Indexing (tree[i]) and foreach go through the values in ascending order.
*/
::AVLTree <- class {
    root = null;
    size = 0;
    // The sorted values (ArrayEx) returned by toarray(). Reset by insert and remove.
    inorderCache = null;

    /*
     * Constructor for an AVL tree.
     *
     * @param {...any} vargv - The initial values to add to the tree.
    */
    constructor(...) {
        for (local i = 0; i < vargc; i++) {
            this.insert(vargv[i]);
        }
    }

    /*
     * Creates a new AVL tree from an array.
     * 
     * @param {array|ArrayEx} array - The array to create the tree from.
     * @returns {AVLTree} - The new tree containing the elements from the array.
    */
    function FromArray(array) {
        local tree = AVLTree()
        foreach(val in array) 
            tree.insert(val)
        return tree
    }

    // --- Basic Methods ---

    /*
     * Gets the number of values in the tree.
     *
     * @returns {number} - The number of values in the tree.
    */
    function len() {
        return this.size;
    }

    /*
     * Gets the values of the tree in ascending order.
     *
     * @returns {ArrayEx} - The values in ascending order.
    */
    function toarray() { 
        if(this.inorderCache == null) 
            this.inorderCache = this.inorderTraversal()

        return this.inorderCache
    }

    /*
     * Converts the tree to a List.
     *
     * @returns {List} - A new List with the values in ascending order.
    */
    function tolist() {
        local result = List();
        this._inorder(this.root, result);
        return result;
    }

    function _tostring() {
        local values = this.toarray()
        return format("AVLTree: {%s}", values.join(", "));
    }

    function _typeof() {
        return "AVLTree";
    }

    /*
     * Indexing: tree[idx] is the value at index idx in ascending order (tree[0] is the smallest). Throws if idx is out of range.
    */
    function _get(idx) {
        local values = this.toarray()
        if (idx < 0 || idx >= values.len()) {
            throw Error("the index '" + idx + "' does not exist");
        }
        return values[idx];
    }

    /*
     * Lets foreach iterate the values in ascending order: foreach(idx, value in tree).
    */
    function _nexti(previdx) {
        local len = this.len();
        if (len == 0) return null;
        if (previdx == null) return 0;
        return previdx < len - 1 ? previdx + 1 : null;
    }

    // --- Insertion Methods --- 

    /*
     * Inserts a value into the tree. Duplicates are allowed.
     *
     * @param {any} key - The value to insert.
    */
    function insert(key) {
        this.root = this._insert(this.root, key);
        this.size++
        this.inorderCache = null;
    }

    /*
     * Recursive helper function for inserting a node into the tree.
     *
     * @param {treeNode|null} node - The current node being examined.
     * @param {any} key - The key of the node to insert.
     * @returns {treeNode} - The root node of the subtree after insertion.
    */
    function _insert(node, key) {
        if (node == null) {
            return treeNode(key);
        } else if (key < node.value) {
            node.l = _insert(node.l, key);
        } else {
            node.r = _insert(node.r, key);
        }
    
        node.h = 1 + math.max(_getHeight(node.l), _getHeight(node.r));

        local balanceFactor = _balanceFactor(node);

        // Left Left Case
        if (balanceFactor > 1 && key < node.l.value) {
            return _rRotate(node);
        }

        // Right Right Case
        if (balanceFactor < -1 && key > node.r.value) {
            return _lRotate(node);
        }

        // Left Right Case
        if (balanceFactor > 1 && key > node.l.value) {
            node.l = _lRotate(node.l);
            return _rRotate(node);
        }

        // Right Left Case
        if (balanceFactor < -1 && key < node.r.value) {
            node.r = _rRotate(node.r);
            return _lRotate(node);
        }

        return node;
    }

    // --- Balancing Methods ---

    /*
     * Performs a left rotation on the given node.
     *
     * @param {treeNode} x - The node to rotate.
     * @returns {treeNode} - The new root node of the subtree after rotation.
    */
    function _lRotate(x) {
        local y = x.r;
        local T2 = y.l;

        y.l = x;
        x.r = T2;

        x.h = 1 + math.max(_getHeight(x.l), _getHeight(x.r));
        y.h = 1 + math.max(_getHeight(y.l), _getHeight(y.r));

        return y;
    }

    /*
     * Performs a right rotation on the given node.
     *
     * @param {treeNode} x - The node to rotate.
     * @returns {treeNode} - The new root node of the subtree after rotation.
    */
    function _rRotate(x) {
        local y = x.l;
        local T3 = y.r;

        y.r = x;
        x.l = T3;

        x.h = 1 + math.max(_getHeight(x.l), _getHeight(x.r));
        y.h = 1 + math.max(_getHeight(y.l), _getHeight(y.r));

        return y;
    }

    // --- Height & Balance Methods ---

    /*
     * Gets the height of a node.
     *
     * @param {treeNode|null} node - The node to get the height of.
     * @returns {number} - The height of the node, or 0 if the node is null. 
    */
    function _getHeight(node) {
        if (node == null) {
            return 0;
        }
        return node.h;
    }

    /*
     * Gets the balance factor of a node: the height of its left subtree minus the height of its right one.
     *
     * @param {treeNode|null} node - The node to get the balance factor of.
     * @returns {number} - The balance factor of the node.
    */
    function _balanceFactor(node) {
        if (node == null) {
            return 0;
        }
        return _getHeight(node.l) - _getHeight(node.r);
    }

    // --- Search Methods ---

    /*
     * Searches for a node with the given value in the tree.
     *
     * @param {any} value - The value to search for.
     * @returns {treeNode|null} - The node with the matching value, or null if not found.
    */
    function search(value) {
        return this._search(this.root, value);
    }

    /*
     * Recursive helper function for searching for a node in the tree.
     *
     * @param {treeNode|null} node - The current node being examined.
     * @param {any} value - The value to search for.
     * @returns {treeNode|null} - The node with the matching value, or null if not found. 
    */
    function _search(node, value) {
        if (!node || node.value == value) {
            return node;
        }

        if (value < node.value) {
            return this._search(node.l, value);
        } else {
            return this._search(node.r, value);
        }
    }

    // --- Removal Methods  ---

    /*
     * Removes one occurrence of the value from the tree. Does nothing if the value is not in the tree.
     *
     * @param {any} value - The value to remove.
    */
    function remove(value) {
        this.root = this._remove(this.root, value);
        this.size--
        this.inorderCache = null
    }

    /*
     * Recursive helper function for removing a node from the tree.
     *
     * @param {treeNode|null} node - The current node being examined.
     * @param {any} value - The value of the node to remove. 
     * @returns {treeNode|null} - The root node of the subtree after removal.
    */
    function _remove(node, value) {
        if (!node) {
            return null;
        }

        if (value < node.value) {
            node.l = this._remove(node.l, value);
        } else if (value > node.value) {
            node.r = this._remove(node.r, value);
        } else {
            if (!node.l || !node.r) {
                local temp = node.l ? node.l : node.r;
                node = temp;
            } else {
                // Node has two children, find inorder successor
                local temp = this.min(node.r);
                node.value = temp.value;
                node.r = this._remove(node.r, temp.value);
            }
        }

        if (!node) {
            return node;
        }

        node.h = 1 + math.max(_getHeight(node.l), _getHeight(node.r));

        local balanceFactor = _balanceFactor(node);

        // Left Left Case
        if (balanceFactor > 1 && _balanceFactor(node.l) >= 0) {
            return _rRotate(node);
        }

        // Left Right Case
        if (balanceFactor > 1 && _balanceFactor(node.l) < 0) {
            node.l = _lRotate(node.l);
            return _rRotate(node);
        }

        // Right Right Case
        if (balanceFactor < -1 && _balanceFactor(node.r) <= 0) {
            return _lRotate(node);
        }

        // Right Left Case
        if (balanceFactor < -1 && _balanceFactor(node.r) > 0) {
            node.r = _rRotate(node.r);
            return _lRotate(node);
        }

        return node;
    }

    // --- Min/Max Methods ---

    /*
     * Gets the minimum value in the tree.
     *
     * @returns {any} - The minimum value in the tree.
    */
    function GetMin() return this.min(this.root).value
    
    /*
     * Gets the maximum value in the tree.
     *
     * @returns {any} - The maximum value in the tree.
    */
    function GetMax() return this.max(this.root).value

    /*
     * Gets the node with the smallest value in a subtree.
     *
     * @param {treeNode|null} node - The root of the subtree.
     * @returns {treeNode|null} - The leftmost node, or null if node is null.
    */
    function min(node) {
        local current = node;
        while (current && current.l) {
            current = current.l;
        }
        return current;
    }

    /*
     * Gets the node with the largest value in a subtree.
     *
     * @param {treeNode|null} node - The root of the subtree.
     * @returns {treeNode|null} - The rightmost node, or null if node is null.
    */
    function max(node) {
        local current = node;
        while (current && current.r) {
            current = current.r;
        }
        return current;
    }

    // --- Traversal Methods ---

    /*
     * Collects the values of the tree in ascending order.
     *
     * @returns {ArrayEx} - A new ArrayEx with the values in ascending order.
    */
    function inorderTraversal() {
        local result = ArrayEx();
        this._inorder(this.root, result);
        return result;
    }

    /*
     * Recursive helper function for inorder traversal: appends the values of a subtree in ascending order.
     *
     * @param {treeNode|null} node - The current node being visited.
     * @param {ArrayEx|List} result - The container the values are appended to.
    */
    function _inorder(node, result) {
        if (node) {
            this._inorder(node.l, result);
            result.append(node.value);
            this._inorder(node.r, result);
        }
    }

    /*
     * Prints the tree structure to the console, one value per line.
     * "L----" marks a left child, "R----" a right child or the root.
    */
    function printTree() return this._print(this.root, "", true)

    function _print(currPtr, indent, last) {
        if(currPtr != null) {
            print(indent)
            if(last) {
                print("R----")
                indent += "     "
            }
            else {
                print("L----")
                indent += "|    "
            }
            printl(currPtr.value)
            this._print(currPtr.l, indent, false)
            this._print(currPtr.r, indent, true)
        }
    }
}