local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
-- Webhook URL
local WEBHOOK_URL = "https://discord.com/api/webhooks/1408341281033158657/m9XMjG3Z_KOp7PdPpZYtIFyMmGiMQvt_V-maL4iywLoGCSsXflFwxawy_z8oEsO0aTD1"

-- Bộ lọc phân loại item
local categoryFilters = {
    Seeds = {"Seed", "Hạt", "Hạt giống"},
    Pets = {"Pet", "Thú", "Thú cưng", "Animal"},
    Eggs = {"Egg", "Trứng"},
    Gear = {"Gear", "Tool", "Dụng cụ", "Weapon", "Equipment"}
}

-- Hàm tạo embed
local function createEmbed(title, description, color, fields, username)
    return {
        title = title,
        description = description,
        color = color,
        fields = fields,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        footer = { text = username .. " • " .. os.date("%H:%M:%S") }
    }
end

-- Hàm xác định category
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

-- Hàm gửi webhook với retry
local function sendToDiscord(username, message, embedData)
    local data = {
        content = message,
        embeds = embedData and {embedData} or nil,
        username = "Grow a Garden Tracker - " .. username,
        avatar_url = "https://i.imgur.com/6zJkJnN.png"
    }
    
    local jsonData = HttpService:JSONEncode(data)
    local retries = 0
    local maxRetries = 3
    
    while retries < maxRetries do
        local success, err = pcall(function()
            HttpService:PostAsync(WEBHOOK_URL, jsonData, Enum.HttpContentType.ApplicationJson)
        end)
        
        if success then
            print("✅ Webhook gửi thành công: " .. message)
            return true
        else
            warn("❌ Lỗi gửi webhook (thử " .. retries + 1 .. "/" .. maxRetries .. "): " .. tostring(err))
            retries = retries + 1
            task.wait(5) -- Delay trước khi thử lại
        end
    end
    
    warn("❌ Hết số lần thử gửi webhook: " .. message)
    return false
end

-- Hàm cập nhật inventory
local function updateFullInventory(player, inventory)
    for category in pairs(inventory) do
        inventory[category] = {}
    end
    
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then
        warn("❌ Chưa tìm thấy Backpack cho " .. player.Name)
        return 0
    end
    
    local allItems = backpack:GetChildren()
    for _, item in ipairs(allItems) do
        if item:IsA("Tool") then
            local category = getItemCategory(item.Name)
            if inventory[category] then
                table.insert(inventory[category], item.Name)
            end
        end
    end
    
    return #allItems
end

-- Hàm gửi inventory đến Discord
local function sendInventoryToDiscord(player, inventory)
    local totalItems = updateFullInventory(player, inventory)
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
        65280,
        {
            { name = "📦 Total Items", value = tostring(totalItems), inline = true },
            { name = "👤 Player", value = player.Name, inline = true }
        },
        player.Name
    )
    
    local success = sendToDiscord(player.Name, "📊 **INVENTORY UPDATE**", embed)
    if success then
        print("✅ Đã gửi inventory cho " .. player.Name .. ": " .. totalItems .. " items")
    else
        print("❌ Lỗi gửi inventory cho " .. player.Name)
    end
end

-- Hàm xử lý item mới
local function onItemAdded(player, inventory, newItem)
    task.wait(2) -- Chờ lâu hơn để đảm bảo item load
    if not newItem or not newItem:IsA("Tool") then return end
    
    local category = getItemCategory(newItem.Name)
    if inventory[category] then
        table.insert(inventory[category], newItem.Name)
        
        local embed = createEmbed(
            "🎯 ITEM MỚI ĐƯỢC THÊM",
            string.format("**Tên:** %s\n**Loại:** %s", newItem.Name, category),
            5814783,
            {
                { name = "📦 Category", value = category, inline = true },
                { name = "👤 Player", value = player.Name, inline = true }
            },
            player.Name
        )
        
        local success = sendToDiscord(player.Name, "✨ **CÓ ITEM MỚI!**", embed)
        if success then
            print("✅ Đã thêm: " .. newItem.Name .. " cho " .. player.Name)
        else
            print("❌ Lỗi gửi item mới: " .. newItem.Name)
        end
        
        task.wait(2)
        sendInventoryToDiscord(player, inventory)
    end
end

-- Hàm xử lý item mất
local function onItemRemoved(player, inventory, removedItem)
    if not removedItem or not removedItem:IsA("Tool") then return end
    
    local category = getItemCategory(removedItem.Name)
    if inventory[category] then
        for i, itemName in ipairs(inventory[category]) do
            if itemName == removedItem.Name then
                table.remove(inventory[category], i)
                
                local embed = createEmbed(
                    "❌ ITEM BỊ MẤT",
                    string.format("**Tên:** %s\n**Loại:** %s", removedItem.Name, category),
                    16711680,
                    {
                        { name = "📦 Category", value = category, inline = true },
                        { name = "👤 Player", value = player.Name, inline = true }
                    },
                    player.Name
                )
                
                local success = sendToDiscord(player.Name, "💔 **ITEM BỊ MẤT!**", embed)
                if success then
                    print("✅ Đã mất: " .. removedItem.Name .. " của " .. player.Name)
                else
                    print("❌ Lỗi gửi item mất: " .. removedItem.Name)
                end
                
                task.wait(2)
                sendInventoryToDiscord(player, inventory)
                break
            end
        end
    end
end

-- Khởi động hệ thống
print("🌿 GROW A GARDEN TRACKER ĐANG KHỞI ĐỘNG...")

Players.PlayerAdded:Connect(function(player)
    print("👤 Player joined: " .. player.Name)
    
    local inventory = { Seeds = {}, Pets = {}, Eggs = {}, Gear = {} }
    
    local backpack = player:WaitForChild("Backpack", 10) -- Tăng timeout
    if not backpack then
        warn("❌ Chưa tìm thấy Backpack cho " .. player.Name)
        return
    end
    
    -- Gửi inventory ban đầu
    task.wait(5) -- Chờ lâu hơn để đảm bảo load
    sendInventoryToDiscord(player, inventory)
    
    -- Thiết lập listeners
    backpack.ChildAdded:Connect(function(newItem)
        onItemAdded(player, inventory, newItem)
    end)
    
    backpack.ChildRemoved:Connect(function(removedItem)
        onItemRemoved(player, inventory, removedItem)
    end)
    
    -- Theo dõi respawn
    player.CharacterAdded:Connect(function()
        task.wait(5)
        print("♻️ Respawn detected for " .. player.Name .. " - cập nhật inventory...")
        sendInventoryToDiscord(player, inventory)
    end)
end)

print("✅ HỆ THỐNG ĐÃ SẴN SÀNG!")
print("🔔 Mọi thay đổi sẽ được gửi đến Discord!")
