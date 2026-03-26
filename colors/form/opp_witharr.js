var itemsD


riveC = [];
var itemsDriveD = [];

/**
 * @summary Keydown için
 */
$("#rtl1").keydown(function (e) {
    if (e.keyCode == 13) {
        getData();
    }
})
/**
 * @summary Ajax iler ürün ağacını alar için
 */
function getData() {
    var keyword = $("#rtl1").val();
    itemsDriveC = [];
    $.ajax({
        url: "/cfc/boyahane.cfc?method=getProdTreeWithName_arr&keyword=" + keyword,
        success: function (retDat) {

            var aaa = JSON.parse(retDat.toLowerCase());
            console.log(aaa)
            for (let i = 0; i < aaa.length; i++) {
                itemsDriveC.push(aaa[i])
                AgacOlustur(aaa[i], 1, i);
            }
        },
    });
}
/**
 * @summary sistem çalıştığında ul1 ve ul3 e sortable katacak
 * mainden çalışılacaksa burada değişiklik yap
 */
$(function () {
    console.log("main Sort")
    var levelim = 0;
    $("#ul1,#ul2,#ul3,.mylevel").sortable({
        connectWith: ".su1",
        receive: function (e, u) {
            if ($(e.target).is("#ul3")) {
                var kaynak = u.sender;
                var hedef = e.target;
                var oge = u.item;
                console.log("Kaynak V")
                console.log(kaynak[0]);
                console.log("Hedef V")
                console.log(hedef);
                console.log("Eeleman V")
                console.log(oge[0]);
                var ind = $(u.item[0]).data("index")
                //console.log(itemsDriveC[ind])
            }
            if ($(hedef).is($("#ul1")) || $(hedef).is($("#ul3"))) {
                $(u.item[0]).data("parent", 0)
            }
        }, items: "li:not(.ui-state-disabled)"
    });
});

function AgacOlustur(item, type, idx) {
    var row = "";
    var level1 = item;
    var level1_tree = item.tree;
    if (type == 1) {
        row += "<li class='list-group-item' data-id='" + level1.stock_id + "' data-index='" + idx + "'><input style='float:left;width:30px'  class='form-control form-control-sm' type='text' value='" + idx + "'>" + level1.product_name + "<input style='float:right;width:30px'  class='form-control form-control-sm' type='text'>";
        if (level1_tree.length) {
            row += "<ul data-tree_id='" + level1.stock_id + "' class='list-group su1 ttre' id='tree_" + level1.stock_id + "'><li style='background:lightgray' class='list-group-item ui-state-disabled'></li>"
            for (let i = 0; i < level1_tree.length; i++) {
                var level2 = level1_tree[i];
                var level2_tree = level1_tree[i].tree;
                row += "<li class='list-group-item' data-id='" + level1_tree[i].stock_id + "' data-index='" + i + "'><input style='float:left;width:30px' value='" + i + "' class='form-control form-control-sm' type='text'>" + level1_tree[i].product_name + "<input style='float:right;width:30px'  class='form-control form-control-sm' type='text'>";
                if (level2_tree.length) {
                    row += "<ul data-tree_id='" + level2.stock_id + "' class='list-group su1 ttre' id='tree_" + level2.stock_id + "'><li style='background:lightgray' class='list-group-item ui-state-disabled'></li>"
                    for (let j = 0; j < level2_tree.length; j++) {
                        row += "<li class='list-group-item' data-id='" + level2_tree[j].stock_id + "' data-index='" + j + "'><input style='float:left;width:30px' value='" + j + "'  class='form-control form-control-sm' type='text'>" + level2_tree[j].product_name + "<input style='float:right;width:30px'  class='form-control form-control-sm' type='text'>";
                        var level3 = level2_tree[j];
                        var level3_tree = level2_tree[j].tree;
                        if (level3_tree.length) {
                            row += "<ul data-tree_id='" + level3.stock_id + "' class='list-group su1 ttre' id='tree_" + level3.stock_id + "'><li style='background:lightgray' class='list-group-item ui-state-disabled'></li>"
                            for (let k = 0; k < level3_tree.length; k++) {
                                row += "<li class='list-group-item' data-id='" + level3_tree[k].stock_id + "' data-index='" + k + "'> <input style='float:left;width:30px' value='" + k + "'  class='form-control form-control-sm' type='text'>" + level3_tree[k].product_name + "<input style='float:right;width:30px'  class='form-control form-control-sm' type='text'>";
                                row += "</li>"

                            }
                            row += "</ul>"
                        }
                        row += "</li>"
                    }
                    row += "</ul>"
                }
                row += "</li>"
            }
            row += "</ul>"
        }
        row += "</li>"
        $("#ul1").append(row)
    }

}
/**
 * @summary Agac Olustuktan sonra sortable yapar
 * @param {string} id  
 */
function makeSortable(id) {
    console.log(elem)
    var elem = document.getElementById(id);
    console.log(elem)
    var levelim = 0;
    $(elem).sortable({
        connectWith: ".su1",
        receive: function (e, u) {
            var kaynak = u.sender;
            var hedef = e.target;
            console.log(kaynak[0]);
            console.log(hedef);
            if ($(hedef).is($("#ul1")) || $(hedef).is($("#ul3"))) {
                $(u.item[0]).data("parent", 0)
            }

        }, items: "li:not(.ui-state-disabled)"
    })
}
function SaveTree() {
    $.ajax({
        type: "get",
        url: "/cfc/boyahane.cfc?method=saveTree",
        data: JSON.stringify(itemsDriveD),
        dataType: "json",
        success: function (sum) {
            // Store the respone in the DOM.
            console.log(sum)
        }
    });
}

$(".supercl").click(function () {
    $(this.children).toggle();
})

function hideerr(elem) {
    $(elem.parentElement.children[1].children).toggle()
    //$(this.parentElement.children).toggle()
}

/*
Filtreleme İçin Kullanabilirsin Taşıma Esnasında
arr.filter(function (ai) {
    if (ai.name == "Emre") {
        return ai
    }
})
*/