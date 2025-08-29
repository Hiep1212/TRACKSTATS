-- 🌟 GROW A GARDEN INVENTORY TRACKER 🌟
-- Dán toàn bộ code này vào executor để test

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Tạo RemoteEvent nếu chưa có
local InventoryUpdateEvent
if not ReplicatedStorage:FindFirstChild("InventoryUpdate") then
    InventoryUpdateEvent = Instance.new("RemoteEvent")
    InventoryUpdateEvent.Name = "InventoryUpdate"
    InventoryUpdateEvent.Parent = ReplicatedStorage
    print("✅ Đã tạo RemoteEvent")
else
    InventoryUpdateEvent = ReplicatedStorage:FindFirstChild("InventoryUpdate")
    print("✅ Đã tìm thấy RemoteEvent")
end

-- Webhook Discord
local WEBHOOK_URL = "https://discord.com/api/webhooks/1408341281033158657/m9XMjG3Z_KOp7PdPpZYtIFyMmGiMQvt_V-maL4iywLoGCSsXflFwxawy_z8oEsO0aTD1"

-- Bộ lọc phân loại item
local categoryFilters = {
    Seeds = {"Seed", "Hạt", "Hạt giống"},
    Pets = {"Pet", "Thú", "Thú cưng", "Animal"},
    Eggs = {"Egg", "Trứng", "Eggs"},
    Gear = {"Gear", "Tool", "Dụng cụ", "Weapon", "Equipment"}
}

local inventory = {
    Seeds = {},
    Pets = {},
    Eggs = {},
    Gear = {}
}

-- 🔥 SERVER SIDE FUNCTIONS
local function sendToDiscord(message, embedData)
    local data = {
        content = message,
        embeds = embedData and {embedData} or nil,
        username = "Grow a Garden Tracker",
        avatar_url = "https://i.imgur.com/6zJkJnN.png"
    }
    
    local success, error = pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode(data))
    end)
    
    if not success then
        warn("❌ Lỗi webhook: " .. tostring(error))
        return false
    end
    return true
end

-- Nhận sự kiện từ client
InventoryUpdateEvent.OnServerEvent:Connect(function(player, action, itemData)
    print("📡 Nhận sự kiện: " .. action)
    
    if action == "inventory_update" then
        local embed = {
            title = "🌿 Grow a Garden Inventory",
            description = itemData.description,
            color = 65280,
            fields = {
                {
                    name = "👤 Player",
                    value = player.Name,
                    inline = true
                },
                {
                    name = "📦 Total Items",
                    value = tostring(itemData.totalItems),
                    inline = true
                }
            },
            timestamp = DateTime.now():ToIsoDate(),
            footer = {
                text = "Auto Update • " .. os.date("%H:%M:%S")
            }
        }
        local success = sendToDiscord("📊 **INVENTORY UPDATE**", embed)
        print(success and "✅ Đã gửi inventory" or "❌ Lỗi gửi inventory")
        
    elseif action == "item_added" then
        local embed = {
            title = "🎯 ITEM MỚI ĐƯỢC THÊM",
            description = string.format("**Tên:** %s\n**Loại:** %s", itemData.itemName, itemData.category),
            color = 5814783,
            fields = {
                {
                    name = "👤 Player",
                    value = player.Name,
                    inline = true
                },
                {
                    name = "📦 Category",
                    value = itemData.category,
                    inline = true
                },
                {
                    name = "🕒 Time",
                    value = os.date("%H:%M:%S"),
                    inline = true
                }
            },
            timestamp = DateTime.now():ToIsoDate(),
            footer = {
                text = "Grow a Garden • New Item"
            }
        }
        local success = sendToDiscord("✨ **CÓ ITEM MỚI!**", embed)
        print(success and "✅ Đã gửi item mới" or "❌ Lỗi gửi item mới")
        
    elseif action == "item_removed" then
        local embed = {
            title = "❌ ITEM BỊ MẤT",
            description = string.format("**Tên:** %s\n**Loại:** %s", itemData.itemName, itemData.category),
            color = 16711680,
            fields = {
                {
                    name = "👤 Player",
                    value = player.Name,
                    inline = true
                },
                {
                    name = "📦 Category",
                    value = itemData.category,
                    inline = true
                },
                {
                    name = "🕒 Time",
                    value = os.date("%H:%M:%S"),
                    inline = true
                }
            },
            timestamp = DateTime.now():ToIsoDate(),
            footer = {
                text = "Grow a Garden • Item Removed"
            }
        }
        local success = sendToDiscord("💔 **ITEM BỊ MẤT!**", embed)
        print(success and "✅ Đã gửi item mất" or "❌ Lỗi gửi item mất")
    end
end)

-- 🔥 CLIENT SIDE FUNCTIONS
local function getItemCategory(itemName)
    itemName = itemName:lower()
    for category, keywords in pairs(categoryFilters) do
        for _, keyword in ipairs(keywords) do
            if itemName:find(keyword:lower()) then
                return category
            end
        end
    end
    return "Other"
end

local function updateFullInventory()
    for category in pairs(inventory) do
        inventory[category] = {}
    end
    
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then
        warn("❌ Chưa tìm thấy Backpack")
        return
    end
    
    local allItems = backpack:GetChildren()
    for _, item in ipairs(allItems) do
        local category = getItemCategory(item.Name)
        if inventory[category] then
            table.insert(inventory[category], item.Name)
        end
    end
end

local function sendInventoryToServer()
    updateFullInventory()
    
    local totalItems = 0
    local description = ""
    
    for category, items in pairs(inventory) do
        totalItems = totalItems + #items
        if #items > 0 then
            description = description .. string.format("**%s (%d):**\n", category, #items)
            for _, itemName in ipairs(items) do
                description = description .. string.format("• %s\n", itemName)
            end
            description = description .. "\n"
        end
    end
    
    if totalItems == 0 then
        description = "📭 Inventory trống rỗng"
    end
    
    InventoryUpdateEvent:FireServer("inventory_update", {
        description = description,
        totalItems = totalItems
    })
    
    print("📊 Đã gửi inventory: " .. totalItems .. " items")
end

local function onItemAdded(newItem)
    task.wait(0.5)
    local category = getItemCategory(newItem.Name)
    if inventory[category] then
        table.insert(inventory[category], newItem.Name)
        
        InventoryUpdateEvent:FireServer("item_added", {
            itemName = newItem.Name,
            category = category
        })
        
        print("🎯 Thêm: " .. newItem.Name)
    end
end

local function onItemRemoved(removedItem)
    local category = getItemCategory(removedItem.Name)
    if inventory[category] then
        for i, itemName in ipairs(inventory[category]) do
            if itemName == removedItem.Name then
                table.remove(inventory[category], i)
                
                InventoryUpdateEvent:FireServer("item_removed", {
                    itemName = removedItem.Name,
                    category = category
                })
                
                print("❌ Mất: " .. removedItem.Name)
                break
            end
        end
    end
end

-- 🚀 KHỞI ĐỘNG HỆ THỐNG
print("🌿 GROW A GARDEN TRACKER ĐANG KHỞI ĐỘNG...")

-- Chờ player load
while not player.Character do
    task.wait(1)
end

local backpack = player:WaitForChild("Backpack")

-- Thiết lập listeners
backpack.ChildAdded:Connect(onItemAdded)
backpack.ChildRemoved:Connect(onItemRemoved)

-- Gửi inventory ban đầu
task.wait(3)
sendInventoryToServer()

-- Theo dõi respawn
player.CharacterAdded:Connect(function()
    task.wait(3)
    print("♻️ Respawn detected")
    sendInventoryToServer()
end)

print("✅ HỆ THỐNG ĐÃ SẴN SÀNG!")
print("👉 Đang theo dõi Backpack của: " .. player.Name)
