-- 🌟 GROW A GARDEN INVENTORY TRACKER (FIXED WEBHOOK) 🌟
-- Dán toàn bộ code này vào executor

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

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

-- 🔥 Hàm gửi webhook SỬ DỤNG EXECUTOR REQUEST
local function sendToDiscord(message, embedData)
    local data = {
        content = message,
        embeds = embedData and {embedData} or nil,
        username = "Grow a Garden Tracker - " .. player.Name,
        avatar_url = "https://i.imgur.com/6zJkJnN.png"
    }
    
    local jsonData = HttpService:JSONEncode(data)
    
    -- Sử dụng request library của executor
    if syn and syn.request then
        -- Synapse X
        local response = syn.request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonData
        })
        return response.StatusCode == 200 or response.StatusCode == 204
        
    elseif request then
        -- Krnl và executor khác
        local response = request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonData
        })
        return response.Success
        
    elseif http and http.request then
        -- Executor có http library
        local response = http.request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonData
        })
        return response.Success
        
    else
        -- Fallback: thử dùng HttpService (có thể fail)
        local success, error = pcall(function()
            HttpService:PostAsync(WEBHOOK_URL, jsonData)
        end)
        return success
    end
end

-- 🔥 Hàm tạo embed
local function createEmbed(title, description, color, fields)
    return {
        title = title,
        description = description,
        color = color,
        fields = fields,
        timestamp = DateTime.now():ToIsoDate(),
        footer = {
            text = player.Name .. " • " .. os.date("%H:%M:%S")
        }
    }
end

-- 🔥 Hàm xác định category
local function getItemCategory(itemName)
    if not itemName then return "Other" end
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

-- 🔥 Hàm cập nhật inventory
local function updateFullInventory()
    for category in pairs(inventory) do
        inventory[category] = {}
    end
    
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then
        warn("❌ Chưa tìm thấy Backpack")
        return 0
    end
    
    local allItems = backpack:GetChildren()
    for _, item in ipairs(allItems) do
        local category = getItemCategory(item.Name)
        if inventory[category] then
            table.insert(inventory[category], item.Name)
        end
    end
    
    return #allItems
end

-- 🔥 Hàm gửi inventory đến Discord
local function sendInventoryToDiscord()
    local totalItems = updateFullInventory()
    local description = ""
    
    for category, items in pairs(inventory) do
        if #items > 0 then
            description = description .. string.format("**%s (%d):**\n", category, #items)
            for _, itemName in ipairs(items) do
                description = description .. string.format("• %s\n", itemName)
            end
            description = description .. "\n"
        end
    end
    
    if description == "" then
        description = "📭 Inventory trống rỗng"
    end
    
    local embed = createEmbed(
        "🌿 Grow a Garden Inventory",
        description,
        65280, -- Màu xanh lá
        {
            {
                name = "📦 Total Items",
                value = tostring(totalItems),
                inline = true
            },
            {
                name = "👤 Player",
                value = player.Name,
                inline = true
            }
        }
    )
    
    local success = sendToDiscord("📊 **INVENTORY UPDATE**", embed)
    if success then
        print("✅ Đã gửi inventory: " .. totalItems .. " items")
    else
        print("❌ Lỗi gửi inventory")
    end
end

-- 🔥 Hàm xử lý item mới
local function onItemAdded(newItem)
    task.wait(1) -- Chờ item load hoàn toàn
    if not newItem or not newItem:IsA("Tool") then return end
    
    local category = getItemCategory(newItem.Name)
    if inventory[category] then
        table.insert(inventory[category], newItem.Name)
        
        local embed = createEmbed(
            "🎯 ITEM MỚI ĐƯỢC THÊM",
            string.format("**Tên:** %s\n**Loại:** %s", newItem.Name, category),
            5814783, -- Màu xanh dương
            {
                {
                    name = "📦 Category",
                    value = category,
                    inline = true
                },
                {
                    name = "👤 Player",
                    value = player.Name,
                    inline = true
                }
            }
        )
        
        local success = sendToDiscord("✨ **CÓ ITEM MỚI!**", embed)
        if success then
            print("✅ Đã thêm: " .. newItem.Name)
        else
            print("❌ Lỗi gửi item mới")
        end
        
        -- Gửi inventory update sau 1 giây
        task.wait(1)
        sendInventoryToDiscord()
    end
end

-- 🔥 Hàm xử lý item mất
local function onItemRemoved(removedItem)
    if not removedItem or not removedItem:IsA("Tool") then return end
    
    local category = getItemCategory(removedItem.Name)
    if inventory[category] then
        for i, itemName in ipairs(inventory[category]) do
            if itemName == removedItem.Name then
                table.remove(inventory[category], i)
                
                local embed = createEmbed(
                    "❌ ITEM BỊ MẤT",
                    string.format("**Tên:** %s\n**Loại:** %s", removedItem.Name, category),
                    16711680, -- Màu đỏ
                    {
                        {
                            name = "📦 Category",
                            value = category,
                            inline = true
                        },
                        {
                            name = "👤 Player",
                            value = player.Name,
                            inline = true
                        }
                    }
                )
                
                local success = sendToDiscord("💔 **ITEM BỊ MẤT!**", embed)
                if success then
                    print("✅ Đã mất: " .. removedItem.Name)
                else
                    print("❌ Lỗi gửi item mất")
                end
                
                -- Gửi inventory update sau 1 giây
                task.wait(1)
                sendInventoryToDiscord()
                break
            end
        end
    end
end

-- 🚀 KHỞI ĐỘNG HỆ THỐNG
print("🌿 GROW A GARDEN TRACKER ĐANG KHỞI ĐỘNG...")
print("👤 Player: " .. player.Name)

-- Chờ player load
while not player.Character do
    task.wait(1)
end

local backpack = player:WaitForChild("Backpack")
print("✅ Đã tìm thấy Backpack")

-- Thiết lập listeners
backpack.ChildAdded:Connect(onItemAdded)
backpack.ChildRemoved:Connect(onItemRemoved)

-- Gửi inventory ban đầu
task.wait(3)
sendInventoryToDiscord()

-- Theo dõi respawn
player.CharacterAdded:Connect(function()
    task.wait(3)
    print("♻️ Respawn detected - cập nhật inventory...")
    sendInventoryToDiscord()
end)

print("✅ HỆ THỐNG ĐÃ SẴN SÀNG!")
print("🔔 Mọi thay đổi sẽ được gửi đến Discord!")
