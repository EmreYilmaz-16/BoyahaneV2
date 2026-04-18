function searchOperations(input, event) {
    if (event.key === "Enter") {
        const query = input.value.trim();
        if (query.length < 3) {
            alert("Lütfen en az 3 karakter giriniz.");
            return;
        }
        fetch(`colors/api/search_operations.cfm?query=${encodeURIComponent(query)}`)
            .then(response => response.json())
            .then(data => {
                const resultDiv = document.getElementById("OperationSearchResult");
                $("#OperationSearchResult").show();
                resultDiv.innerHTML = "";
                if (data.length === 0) {
                    resultDiv.innerHTML = `<div style="padding:12px 16px;font-size:0.83rem;color:#94a3b8;text-align:center;"><i class="fas fa-search me-2"></i>Sonuç bulunamadı.</div>`;
                    return;
                }
                data.forEach((op, idx) => {
                    const opCard = document.createElement("div");
                    opCard.style.cssText = `padding:9px 14px;cursor:pointer;display:flex;align-items:center;gap:10px;border-bottom:1px solid #f1f5f9;transition:background 0.12s;${idx === data.length - 1 ? 'border-bottom:none;' : ''}`;
                    opCard.innerHTML = `
                        <div style="width:32px;height:32px;background:linear-gradient(135deg,var(--primary-dk),var(--primary));border-radius:7px;display:flex;align-items:center;justify-content:center;flex-shrink:0;">
                            <i class="fas fa-cog" style="font-size:0.72rem;color:#fff;"></i>
                        </div>
                        <div style="overflow:hidden;flex:1;">
                            <div style="font-size:0.84rem;font-weight:600;color:#1e293b;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${op.product_name}</div>
                            <div style="font-size:0.7rem;color:#94a3b8;margin-top:1px;">${op.product_code}</div>
                        </div>
                        <i class="fas fa-plus" style="font-size:0.65rem;color:var(--accent);flex-shrink:0;"></i>
                    `;
                    opCard.addEventListener("mouseenter", () => opCard.style.background = "#f8fafc");
                    opCard.addEventListener("mouseleave", () => opCard.style.background = "");
                    opCard.addEventListener("click", () => AddOperationToTree(op.product_id, op.stock_id));
                    resultDiv.appendChild(opCard);
                });
            })
            .catch(error => {
                console.error("Arama hatası:", error);
                alert("Arama sırasında bir hata oluştu.");
            });
    }
}
let _pickerTargetCardId = null;
let _pickerSearchTimer = null;

function openProductPicker(cardId) {
    _pickerTargetCardId = cardId;
    document.getElementById('productPickerSearch').value = '';
    document.getElementById('productPickerList').innerHTML = '';
    document.getElementById('productPickerModal').style.display = 'block';
    setTimeout(() => document.getElementById('productPickerSearch').focus(), 80);
}

function closeProductPicker() {
    document.getElementById('productPickerModal').style.display = 'none';
    _pickerTargetCardId = null;
}
function searchProductPicker(query) {
    clearTimeout(_pickerSearchTimer);
    const list = document.getElementById('productPickerList');
    if (query.trim().length < 2) {
        list.innerHTML = `<div style="padding:14px 16px;font-size:0.82rem;color:#94a3b8;text-align:center;"><i class="fas fa-search me-2"></i>En az 2 karakter girin.</div>`;
        return;
    }
    list.innerHTML = `<div style="padding:14px 16px;font-size:0.82rem;color:#94a3b8;text-align:center;"><i class="fas fa-spinner fa-spin me-2"></i>Aranıyor...</div>`;
    _pickerSearchTimer = setTimeout(() => {
        fetch(`colors/api/search_operations.cfm?query=${encodeURIComponent(query.trim())}`)
            .then(r => r.json())
            .then(data => {
                if (data.length === 0) {
                    list.innerHTML = `<div style="padding:14px 16px;font-size:0.82rem;color:#94a3b8;text-align:center;"><i class="fas fa-box-open me-2"></i>Sonuç bulunamadı.</div>`;
                    return;
                }
                list.innerHTML = '';
                data.forEach((p, idx) => {
                    const item = document.createElement('div');
                    item.style.cssText = `padding:10px 16px;cursor:pointer;display:flex;align-items:center;gap:10px;border-bottom:1px solid #f1f5f9;transition:background 0.12s;${idx === data.length - 1 ? 'border-bottom:none;' : ''}`;
                    item.innerHTML = `
                        <div style="width:30px;height:30px;background:linear-gradient(135deg,var(--primary-dk),var(--primary));border-radius:6px;display:flex;align-items:center;justify-content:center;flex-shrink:0;">
                            <i class="fas fa-flask" style="font-size:0.68rem;color:#fff;"></i>
                        </div>
                        <div style="overflow:hidden;flex:1;">
                            <div style="font-size:0.83rem;font-weight:600;color:#1e293b;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${p.product_name}</div>
                            <div style="font-size:0.69rem;color:#94a3b8;">${p.product_code}</div>
                        </div>
                        <i class="fas fa-plus" style="font-size:0.65rem;color:var(--accent);flex-shrink:0;"></i>
                    `;
                    item.addEventListener('mouseenter', () => item.style.background = '#f8fafc');
                    item.addEventListener('mouseleave', () => item.style.background = '');
                    item.addEventListener('click', () => addProductToCard(p));
                    list.appendChild(item);
                });
            })
            .catch(() => {
                list.innerHTML = `<div style="padding:14px 16px;font-size:0.82rem;color:#e53e3e;"><i class="fas fa-exclamation-circle me-2"></i>Arama hatası.</div>`;
            });
    }, 300);
}


function addProductToCard(product) {
    const card = document.getElementById(_pickerTargetCardId);
    if (!card) return;

    let list = card.querySelector('.tree-sortable-list');
    if (!list) {
        list = document.createElement('div');
        list.className = 'tree-sortable-list';
        card.appendChild(list);
        $(list).sortable({ axis: 'y', opacity: 0.7, cancel: 'input,button' });
    }

    const ts2 = Date.now();
    const nodeId = `tree-node-new-${product.product_id}-${ts2}`;
    const node = document.createElement('div');
    node.id = nodeId;
    node.className = 'tree-node';
    node.dataset.productId = product.product_id;
    node.dataset.relatedId = product.product_id;
    node.dataset.lineNumber = list.children.length + 1;
    node.dataset.productcatId = product.productcat_id ?? 0;
    node.innerHTML = `
        <input type="number" class="tree-line-input" value="${list.children.length + 1}" min="1" step="1" data-node-id="${nodeId}"
            title="Sıra"
            style="width:36px;padding:2px 3px;font-size:0.72rem;font-weight:600;border:1px solid #dde3ec;border-radius:5px;text-align:center;color:#1e293b;background:#f8fafc;flex-shrink:0;"
            onclick="event.stopPropagation();">
        <div style="width:20px;height:20px;background:linear-gradient(135deg,var(--primary-dk),var(--primary));border-radius:4px;display:flex;align-items:center;justify-content:center;flex-shrink:0;">
            <i class="fas fa-flask" style="font-size:0.55rem;color:#fff;"></i>
        </div>
        <div style="overflow:hidden;flex:1;">
            <div style="font-size:0.76rem;font-weight:600;color:#1e293b;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${product.product_name}</div>
        </div>
        <div style="display:flex;align-items:center;gap:5px;flex-shrink:0;">
            <div style="display:flex;flex-direction:column;align-items:center;gap:2px;">
                <input type="number" class="tree-amount-input" value="1" min="0" step="any" data-node-id="${nodeId}"
                    title="Miktar"
                    style="width:54px;padding:2px 4px;font-size:0.72rem;font-weight:600;border:1px solid #dde3ec;border-radius:5px;text-align:right;color:#1e293b;background:#f8fafc;flex-shrink:0;"
                    onclick="event.stopPropagation();">
            </div>
    `;
    list.appendChild(node);

    // record-count güncelle
    const countEl = card.querySelector('.record-count');
    if (countEl) countEl.textContent = list.children.length;

    closeProductPicker();
}

function AddOperationToTree(pid, sid) {
    console.log("Seçilen Ürün ID:", pid);
    console.log("Seçilen Stok ID:", sid);
    fetch(`colors/api/getTree.cfm?stock_id=${sid}`)
        .then(response => response.json())
        .then(data => {
            console.log("Ürün Ağacı Verisi:", data);
            const treeArea = document.getElementById("treeArea");

            let currentCard = null;
            let currentList = null;
            let itemCount = 0;
            const ts = Date.now();

            const flushCard = () => {
                if (currentCard && currentList) {
                    currentCard.querySelector(".record-count").textContent = itemCount;
                    currentCard.appendChild(currentList);
                    $(currentList).sortable({ axis: "y", opacity: 0.7, cancel: 'input,button' });
                    treeArea.appendChild(currentCard);
                }
            };

            // tüm kartlar eklendikten sonra treeArea sortable yapılacak
            const initTreeSortable = () => {
                $(treeArea).sortable({
                    handle: '.grid-card-header',
                    opacity: 0.75,
                    placeholder: 'card-sort-placeholder',
                    forcePlaceholderSize: true,
                    cancel: 'button, .record-count'
                });
            };

            data.forEach((element, idx) => {
                if (element.operation_type_id != 0) {
                    // Önceki kartı kaydet
                    flushCard();
                    itemCount = 0;

                    // Yeni card başlat
                    const cardId = `op-card-${element.operation_type_id}-${ts}-${idx}`;
                    currentCard = document.createElement("div");
                    currentCard.className = "grid-card mb-3";
                    currentCard.id = cardId;
                    currentCard.innerHTML = `
                        <div class="grid-card-header">
                            <div class="grid-card-header-title">
                                <i class="fas fa-cog"></i>
                                ${element.operation_type}
                            </div>
                            <div style="display:flex;align-items:center;gap:8px;">
                                <span class="record-count">0</span>
                                <button class="btn-add-product" onclick="openProductPicker('${cardId}')" title="Ürün Ekle"
                                    style="width:26px;height:26px;background:var(--accent);border:none;border-radius:6px;color:#fff;cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:0.75rem;flex-shrink:0;">
                                    <i class="fas fa-plus"></i>
                                </button>

                            </div>
                        </div>
                    `;
                    currentList = document.createElement("div");
                    currentList.className = "tree-sortable-list";
                } else {
                    // Başlık yoksa varsayılan kart
                    if (!currentCard) {
                        currentCard = document.createElement("div");
                        currentCard.className = "grid-card mb-3";
                        currentCard.id = `op-card-default-${ts}`;
                        const defCardId = `op-card-default-${ts}`;
                        currentCard.innerHTML = `
                            <div class="grid-card-header">
                                <div class="grid-card-header-title">
                                    <i class="fas fa-cubes"></i> Ürünler
                                </div>
                                <div style="display:flex;align-items:center;gap:8px;">
                                    <span class="record-count">0</span>
                                    <button class="btn-add-product" onclick="openProductPicker('${defCardId}')" title="Ürün Ekle"
                                        style="width:26px;height:26px;background:var(--accent);border:none;border-radius:6px;color:#fff;cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:0.75rem;flex-shrink:0;">
                                        <i class="fas fa-plus"></i>
                                    </button>
                                </div>
                            </div>
                        `;
                        currentList = document.createElement("div");
                        currentList.className = "tree-sortable-list";
                    }

                    const nodeId = `tree-node-${element.product_id}-${ts}-${idx}`;
                    const node = document.createElement("div");
                    node.id = nodeId;
                    node.className = "tree-node";
                    node.dataset.productId = element.product_id;
                    node.dataset.relatedId = element.related_id;
                    node.dataset.lineNumber = element.line_number;
                    node.dataset.productcatId = element.productcat_id ?? 0;
                    node.innerHTML = `
                        <input type="number" class="tree-line-input" value="${element.line_number ?? idx + 1}" min="1" step="1" data-node-id="${nodeId}"
                            title="Sıra"
                            style="width:36px;padding:2px 3px;font-size:0.72rem;font-weight:600;border:1px solid #dde3ec;border-radius:5px;text-align:center;color:#1e293b;background:#f8fafc;flex-shrink:0;"
                            onclick="event.stopPropagation();">
                        <div style="width:20px;height:20px;background:linear-gradient(135deg,var(--primary-dk),var(--primary));border-radius:4px;display:flex;align-items:center;justify-content:center;flex-shrink:0;">
                            <i class="fas fa-flask" style="font-size:0.55rem;color:#fff;"></i>
                        </div>
                        <div style="overflow:hidden;flex:1;">
                            <div style="font-size:0.76rem;font-weight:600;color:#1e293b;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${element.product_name}</div>
                        </div>
                        <input type="number" class="tree-amount-input" value="${element.amount ?? 1}" min="0" step="any" data-node-id="${nodeId}"
                            title="Miktar"
                            style="width:54px;padding:2px 4px;font-size:0.72rem;font-weight:600;border:1px solid #dde3ec;border-radius:5px;text-align:right;color:#1e293b;background:#f8fafc;flex-shrink:0;"
                            onclick="event.stopPropagation();">
                    `;
                    currentList.appendChild(node);
                    itemCount++;
                }
            });

            // Son kartı da ekle
            flushCard();
            initTreeSortable();
        })
        .catch(error => {
            console.error("Ağaç verisi alınırken hata:", error);
            alert("Ağaç verisi alınırken bir hata oluştu.");
        });

    $("#OperationSearchResult").hide();
}
function serializeTree() {
    const treeArea = document.getElementById('treeArea');
    const cards = treeArea.querySelectorAll('.grid-card');
    const payload = [];

    cards.forEach(card => {
        // Card başlığı ve operation_type_id'yi id'den parse et
        const titleEl = card.querySelector('.grid-card-header-title');
        const operationType = titleEl ? titleEl.childNodes[titleEl.childNodes.length - 1].textContent.trim() : '';
        const idParts = card.id.split('-');  // op-card-{op_type_id}-{ts}-{idx}
        const operationTypeId = (idParts[2] && idParts[2] !== 'default') ? parseInt(idParts[2]) : 0;

        const items = [];
        const nodes = card.querySelectorAll('.tree-node');
        nodes.forEach(node => {
            const lineInput = node.querySelector('.tree-line-input');
            const amountInput = node.querySelector('.tree-amount-input');
            items.push({
                product_id: parseInt(node.dataset.productId) || 0,
                related_id: parseInt(node.dataset.relatedId) || 0,
                line_number: lineInput ? parseInt(lineInput.value) : 0,
                amount: amountInput ? parseFloat(amountInput.value) : 0
            });
        });

        payload.push({
            operation_type_id: operationTypeId,
            operation_type: operationType,
            items: items
        });
    });

    return payload;
}
function saveTree() {
    const payload = serializeTree();
    if (payload.length === 0) {
        alert('Kaydedilecek veri bulunamadı.');
        return;
    }
    console.log('Gönderilecek payload:', JSON.stringify(payload, null, 2));
    var renkTonu = renkTonuHesapla();

    fetch('colors/api/save_tree.cfm', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ color_id: new URLSearchParams(location.search).get('color_id') || 0, tree: payload, renk_tonu: renkTonu })
    })
        .then(r => r.json())
        .then(res => {
            if (res.success) {
                alert('Kaydedildi!');
            } else {
                alert('Hata: ' + (res.message || 'Bilinmeyen hata'));
            }
        })
        .catch(err => {
            console.error('Kayıt hatası:', err);
            alert('Sunucu hatası oluştu.');
        });
}
function LoadColorTree(stockId) {
    const treeArea = document.getElementById('treeArea');
    treeArea.innerHTML = '';

    fetch(`colors/api/getColorTree.cfm?stock_id=${stockId}`)
        .then(r => r.json())
        .then(data => {
            if (!data || data.length === 0) return;

            const ts = Date.now();

            data.forEach((op, opIdx) => {
                const cardId = `op-card-${op.operation_type_id}-${ts}-${opIdx}`;
                const card = document.createElement('div');
                card.className = 'grid-card mb-3';
                card.id = cardId;
                card.innerHTML = `
                    <div class="grid-card-header">
                        <div class="grid-card-header-title">
                            <i class="fas fa-cog"></i>
                            ${op.operation_type}
                        </div>
                        <div style="display:flex;align-items:center;gap:8px;">
                            <span class="record-count">${op.items.length}</span>
                            <button class="btn-add-product" onclick="openProductPicker('${cardId}')" title="Ürün Ekle"
                                style="width:26px;height:26px;background:var(--accent);border:none;border-radius:6px;color:#fff;cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:0.75rem;flex-shrink:0;">
                                <i class="fas fa-plus"></i>
                            </button>
                        </div>
                    </div>
                `;

                const list = document.createElement('div');
                list.className = 'tree-sortable-list';

                op.items.forEach((item, idx) => {
                    const nodeId = `tree-node-${item.product_id}-${ts}-${opIdx}-${idx}`;
                    const node = document.createElement('div');
                    node.id = nodeId;
                    node.className = 'tree-node';
                    node.dataset.productId = item.product_id;
                    node.dataset.relatedId = item.related_id;
                    node.dataset.lineNumber = item.line_number;
                    node.dataset.productcatId = item.productcat_id ?? 0;
                    node.innerHTML = `
                        <input type="number" class="tree-line-input" value="${item.line_number}" min="1" step="1" data-node-id="${nodeId}"
                            title="Sıra"
                            style="width:36px;padding:2px 3px;font-size:0.72rem;font-weight:600;border:1px solid #dde3ec;border-radius:5px;text-align:center;color:#1e293b;background:#f8fafc;flex-shrink:0;"
                            onclick="event.stopPropagation();">
                        <div style="width:20px;height:20px;background:linear-gradient(135deg,var(--primary-dk),var(--primary));border-radius:4px;display:flex;align-items:center;justify-content:center;flex-shrink:0;">
                            <i class="fas fa-flask" style="font-size:0.55rem;color:#fff;"></i>
                        </div>
                        <div style="overflow:hidden;flex:1;">
                            <div style="font-size:0.76rem;font-weight:600;color:#1e293b;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${item.product_name}</div>
                        </div>
                        <input type="number" class="tree-amount-input" value="${item.amount}" min="0" step="any" data-node-id="${nodeId}"
                            title="Miktar"
                            style="width:54px;padding:2px 4px;font-size:0.72rem;font-weight:600;border:1px solid #dde3ec;border-radius:5px;text-align:right;color:#1e293b;background:#f8fafc;flex-shrink:0;"
                            onclick="event.stopPropagation();">
                    `;
                    list.appendChild(node);
                });

                $(list).sortable({ axis: 'y', opacity: 0.7, cancel: 'input,button' });
                card.appendChild(list);
                treeArea.appendChild(card);
            });

            $(treeArea).sortable({
                handle: '.grid-card-header',
                opacity: 0.75,
                placeholder: 'card-sort-placeholder',
                forcePlaceholderSize: true,
                cancel: 'button, .record-count'
            });
        })
        .catch(err => {
            console.error('Ağaç yüklenirken hata:', err);
        });
}
// ─────────────────────────────────────────────────────────
function get_elements_by_productcatid(productcat_id) {
    return Array.from(document.querySelectorAll('.tree-node'))
        .filter(node => parseInt(node.dataset.productcatId) === parseInt(productcat_id));
}

function renkTonuHesapla() {
    var OranToplami = 0;
    var colorItems = get_elements_by_productcatid(5)
    for (let i = 0; i < colorItems.length; i++) {
        var elem = colorItems[i]
        console.log(elem)
        var MiktarElem = elem.querySelector(".tree-amount-input")
        console.log(MiktarElem.value)
        //mk.value=1
        OranToplami = OranToplami + parseInt(MiktarElem.value)
    }
    var RenkTonu = 1;
    if (OranToplami < 0.2) { } else if (OranToplami < 0.5) { RenkTonu = 2 } else if (OranToplami < 1) { RenkTonu = 3 } else if (OranToplami < 2) { RenkTonu = 4 } else if (OranToplami < 3) { RenkTonu = 5 } else if (OranToplami > 3) { RenkTonu = 6 }
    console.log(RenkTonu)
    document.getElementById("renkTonu").textContent = RenkTonu
    return RenkTonu;

}