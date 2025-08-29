local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")

-- Webhook Discord của bạn
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

-- Hàm gửi dữ liệu đến Discord
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
        warn("Lỗi gửi webhook: " .. tostring(error))
    end
end

-- Hàm xác định category
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

-- Hàm tạo embed inventory
local function createInventoryEmbed()
    local totalItems = 0
    local description = ""
    
    for category, items in pairs(inventory) do
        totalItems = totalItems + #items
        if #items > 0 then
            description = description .. string.format("**%s (%d):**\n", category, #items)
            for i, itemName in ipairs(items) do
                description = description .. string.format("• %s\n", itemName)
            end
            description = description .. "\n"
        end
    end
    
    if totalItems == 0 then
        description = "📭 Inventory trống rỗng"
    end
    
    return {
        title = "🌿 Grow a Garden Inventory",
        description = description,
        color = 65280, -- Màu xanh lá
        fields = {
            {
                name = "👤 Player",
                value = player.Name,
                inline = true
            },
            {
                name = "📦 Total Items",
                value = tostring(totalItems),
                inline = true
            }
        },
        timestamp = DateTime.now():ToIsoDate(),
        footer = {
            text = "Auto Update • " .. os.date("%H:%M:%S")
        }
    }
end

-- Hàm cập nhật toàn bộ inventory
local function updateFullInventory()
    for category in pairs(inventory) do
        inventory[category] = {}
    end
    
    local allItems = backpack:GetChildren()
    
    for _, item in ipairs(allItems) do
        local category = getItemCategory(item.Name)
        if inventory[category] then
            table.insert(inventory[category], item.Name)
        end
    end
end

-- Hàm gửi inventory hiện tại
local function sendInventoryToDiscord()
    updateFullInventory()
    local embed = createInventoryEmbed()
    sendToDiscord("📊 **INVENTORY UPDATE**", embed)
    print("✅ Đã gửi inventory đến Discord!")
end

-- Hàm xử lý khi có item mới (THÊM VÀO)
local function onItemAdded(newItem)
    local category = getItemCategory(newItem.Name)
    
    if inventory[category] then
        table.insert(inventory[category], newItem.Name)
        
        -- Gửi thông báo ITEM MỚI
        local embed = {
            title = "🎯 **ITEM MỚI ĐƯỢC THÊM**",
            description = string.format("**Tên:** %s\n**Loại:** %s", newItem.Name, category),
            color = 5814783, -- Màu xanh dương
            fields = [
                {
                    name = "👤 Player",
                    value = player.Name,
                    inline = true
                },
                {
                    name = "📦 Category",
                    value = category,
                    inline = true
                },
                {
                    name = "🕒 Time",
                    value = os.date("%H:%M:%S"),
                    inline = true
                }
            ],
            timestamp = DateTime.now():ToIsoDate(),
            footer = {
                text = "Grow a Garden • New Item"
            }
        }
        
        sendToDiscord("✨ **CÓ ITEM MỚI!**", embed)
        
        -- Gửi luôn inventory update
        task.wait(1)
        sendInventoryToDiscord()
    end
end

-- Hàm xử lý khi mất item (BỊ LẤY ĐI)
local function onItemRemoved(removedItem)
    local category = getItemCategory(removedItem.Name)
    local foundIndex = nil
    
    if inventory[category] then
        for i, itemName in ipairs(inventory[category]) do
            if itemName == removedItem.Name then
                foundIndex = i
                break
            end
        end
        
        if foundIndex then
            table.remove(inventory[category], foundIndex)
            
            -- Gửi thông báo MẤT ITEM
            local embed = {
                title = "❌ **ITEM BỊ MẤT**",
                description = string.format("**Tên:** %s\n**Loại:** %s", removedItem.Name, category),
                color = 16711680, -- Màu đỏ
                fields = [
                    {
                        name = "👤 Player",
                        value = player.Name,
                        inline = true
                    },
                    {
                        name = "📦 Category",
                        value = category,
                        inline = true
                    },
                    {
                        name = "🕒 Time",
                        value = os.date("%H:%M:%S"),
                        inline = true
                    }
                ],
                timestamp = DateTime.now():ToIsoDate(),
                footer = {
                    text = "Grow a Garden • Item Removed"
                }
            }
            
            sendToDiscord("💔 **ITEM BỊ MẤT!**", embed)
            
            -- Gửi luôn inventory update
            task.wait(1)
            sendInventoryToDiscord()
        end
    end
end

-- Khởi động hệ thống
print("🔄 Đang khởi động hệ thống theo dõi...")
updateFullInventory()

-- Gửi inventory ban đầu
task.wait(2)
sendInventoryToDiscord()

-- Thiết lập listeners
backpack.ChildAdded:Connect(onItemAdded)
backpack.ChildRemoved:Connect(onItemRemoved)

-- Theo dõi respawn
player.CharacterAdded:Connect(function()
    task.wait(3)
    print("♻️ Nhân vật respawn, cập nhật inventory...")
    sendToDiscord("🔄 **NHÂN VẬT RESPAWN** - Đang cập nhật inventory...")
    sendInventoryToDiscord()
end)

print("✅ Hệ thống theo dõi đã sẵn sàng!")
