
    <style>
        .form {
            display: flex;
        }

        .form>div {
            display: inline-block;
            vertical-align: top;
        }

        #treeviewDriveC,
        #treeviewDriveD {
            margin-top: 10px;
        }

        .drive-header {
            min-height: auto;
            padding: 0px;
            cursor: default;
        }

        .drive-panel {
            padding: 20px 30px;
            font-size: 115%;
            font-weight: bold;
            border-right: 1px solid rgba(165, 165, 165, 0.4);
            height: 100%;
        }

        .drive-panel:last-of-type {
            border-right: none;
        }
    </style>
</head>

<body>
    <div class="demo-container">

        <div class="form">
            <div>
    <input type="text" class="form-control" id="rtl1" placeholder="Renk">
    <input type="text" class="form-control" placeholder="İşlem"></div>
            <div class="drive-panel">
                <div class="drive-header dx-treeview-item"><div class="dx-treeview-item-content"><i class="dx-icon dx-icon-activefolder"></i><span>Drive C:</span></div></div>
                <div id="treeviewDriveC"></div>
            </div>
            <div class="drive-panel">
                <div class="drive-header dx-treeview-item"><div class="dx-treeview-item-content"><i class="dx-icon dx-icon-activefolder"></i><span>Drive D:</span></div></div>
                <div id="treeviewDriveD"></div>
            </div>  
        </div>
    </div>
    <script>
    var itemsDriveD = [];
var itemsDriveC = [];

$("#rtl1").keydown(function(e){
    console.log(e)
if(e.keyCode==13){
   var elem=document.getElementById("rtl1")
   setC(elem) 
}

})
function setC(elem) {
    console.log(elem)
    itemsDriveC = [];
    setData();
    var keyword = $(elem).val()
if(keyword.length>3){
    $.ajax({
        url: "/cfc/boyahane.cfc?method=getProdTreeWithName&keyword=" + keyword,
        success: function (retDat) {
            console.log(JSON.parse(retDat.toLowerCase()))
            var aaa = JSON.parse(retDat.toLowerCase());       

  for (let i = 0; i < aaa.length; i++) {
                var obj = new Object;
                obj.name = aaa[i].name;
                if(aaa[i].parentid){ obj.parentId = aaa[i].parentid;}
                obj.icon = aaa[i].icon;
                 obj.id = aaa[i].id;
                obj.isDirectory = aaa[i].isdirectory;
               
                 obj.expanded = aaa[i].expanded;
                
                itemsDriveC.push(obj)
            }
setData()

        }
    });
    }
}
        function setData () {
            console.log(itemsDriveC)
            createTreeView('#treeviewDriveC', itemsDriveC);
            createTreeView('#treeviewDriveD', itemsDriveD);

            createSortable('#treeviewDriveC', 'driveC');
            createSortable('#treeviewDriveD', 'driveD');
        };

       function createTreeView(selector, items) {
    $(selector).dxTreeView({
        items: items,
        expandNodesRecursive: false,
        dataStructure: 'plain',
        width: 250,
        height: 380,
        displayExpr: 'name'
    });
}

function createSortable(selector, driveName) {
    $(selector).dxSortable({
        filter: ".dx-treeview-item",
        group: "shared",
        data: driveName,
        allowDropInsideItem: true,
        allowReordering: true,
        onDragChange: function(e) {
            if(e.fromComponent === e.toComponent) {
                var $nodes = e.element.find(".dx-treeview-node");
                var isDragIntoChild = $nodes.eq(e.fromIndex).find($nodes.eq(e.toIndex)).length > 0;
                if(isDragIntoChild) {
                    e.cancel = true;
                }
            }
        },
        onDragEnd: function(e) {
            if(e.fromComponent === e.toComponent && e.fromIndex === e.toIndex) {
                return;
            }
            
            var fromTreeView = getTreeView(e.fromData);
            console.log(e)
            var toTreeView = getTreeView(e.toData);

            var fromNode = findNode(fromTreeView, e.fromIndex);
            var toNode = findNode(toTreeView, calculateToIndex(e));

            if(e.dropInsideItem && toNode !== null && !toNode.itemData.isDirectory) {
                return;
            }

            var fromTopVisibleNode = getTopVisibleNode(fromTreeView);
            var toTopVisibleNode = getTopVisibleNode(toTreeView);

            var fromItems = fromTreeView.option('items');
            var toItems = toTreeView.option('items');
            moveNode(fromNode, toNode, fromItems, toItems, e.dropInsideItem);

            fromTreeView.option("items", fromItems);
            toTreeView.option("items", toItems);
            fromTreeView.scrollToItem(fromTopVisibleNode);
            toTreeView.scrollToItem(toTopVisibleNode);
        }
    });
}

function getTreeView(driveName) {
    return driveName === 'driveC'
        ? $('#treeviewDriveC').dxTreeView('instance')
        : $('#treeviewDriveD').dxTreeView('instance');
}

function calculateToIndex(e) {
    if(e.fromComponent != e.toComponent || e.dropInsideItem) {
        return e.toIndex;
    }

    return e.fromIndex >= e.toIndex
        ? e.toIndex
        : e.toIndex + 1;
}

function findNode(treeView, index) {
    var nodeElement = treeView.element().find('.dx-treeview-node')[index];
    if(nodeElement) {
        return findNodeById(treeView.getNodes(), nodeElement.getAttribute('data-item-id'));
    }
    return null;
}

function findNodeById(nodes, id) {
    for(var i = 0; i < nodes.length; i++) {
        if(nodes[i].itemData.id == id) {
            return nodes[i];
        }
        if(nodes[i].children) {
            var node = findNodeById(nodes[i].children, id);
            if(node != null) {
                return node;
            }
        }
    }
    return null;
}

function moveNode(fromNode, toNode, fromItems, toItems, isDropInsideItem) {
    var fromIndex = findIndex(fromItems, fromNode.itemData.id);
    fromItems.splice(fromIndex, 1);

    var toIndex = toNode === null || isDropInsideItem
        ? toItems.length
        : findIndex(toItems, toNode.itemData.id);
    toItems.splice(toIndex, 0, fromNode.itemData);

    moveChildren(fromNode, fromItems, toItems);
    if(isDropInsideItem) {
        fromNode.itemData.parentId = toNode.itemData.id;
    } else {
        fromNode.itemData.parentId = toNode != null
            ? toNode.itemData.parentId
            : undefined;
    }
}

function moveChildren(node, fromItems, toItems) {
    if(!node.itemData.isDirectory) {
        return;
    }

    node.children.forEach(function(child) {
        if(child.itemData.isDirectory) {
            moveChildren(child, fromItems, toItems);
        }

        var fromIndex = findIndex(fromItems, child.itemData.id);
        fromItems.splice(fromIndex, 1);
        toItems.splice(toItems.length, 0, child.itemData);
    });
}

function findIndex(array, id) {
    var idsArray = array.map(function(elem) { return elem.id; });
    return idsArray.indexOf(id);
}

function getTopVisibleNode(component) {
    var treeViewElement = component.element().get(0);
    var treeViewTopPosition = treeViewElement.getBoundingClientRect().top;
    var nodes = treeViewElement.querySelectorAll(".dx-treeview-node");
    for(var i = 0; i < nodes.length; i++) {
        var nodeTopPosition = nodes[i].getBoundingClientRect().top;
        if(nodeTopPosition >= treeViewTopPosition) {
            return nodes[i];
        }
    }

    return null;
}
    </script>
