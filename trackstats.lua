local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Webhook URL từ bạn cung cấp
local WEBHOOK_URL = "https://discord.com/api/webhooks/1340257240308777002/f1ARtVXe6Qm_P4piWYTVBCd3nB3eFpE4sAQN2uPOrnbWIoHWnVgq6CcWmp-jVZdwfeSc"

-- Hàm gửi message đến Discord webhook
local function sendToWebhook(username, message)
    local data = {
        ["content"] = "**Tài khoản: " .. username .. "**\n" .. message,
        ["username"] = "Grow a Garden Inventory Bot",  -- Tên bot hiển thị
        ["avatar_url"] = "https://example.com/avatar.png"  -- Optional: Avatar URL
    }
    local jsonData = HttpService:JSONEncode(data)
    
    local success, err = pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, jsonData, Enum.HttpContentType.ApplicationJson)
    end)
    
    if not success then
        warn("Lỗi gửi webhook: " .. tostring(err))
    end
end

-- Hàm lấy toàn bộ inventory dưới dạng string
local function getInventoryString(inventoryFolder)
    local invStr = ""
    
    -- Duyệt qua các category: Seeds, Eggs, Pets, Gears
    for _, category in ipairs({"Seeds", "Eggs", "Pets", "Gears"}) do
        local catFolder = inventoryFolder:FindFirstChild(category)
        if catFolder then
            invStr = invStr .. "**" .. category .. ":**\n"
            for _, item in ipairs(catFolder:GetChildren()) do
                local quantity = item.Value or 0  -- Giả sử Value là số lượng
                invStr = invStr .. "- " .. item.Name .. ": " .. quantity .. "\n"
            end
            invStr = invStr .. "\n"
        end
    end
    
    return invStr ~= "" and invStr or "Inventory rỗng."
end

-- Khi player join
Players.PlayerAdded:Connect(function(player)
    -- Kiểm tra tên account
    local username = player.Name
    sendToWebhook(username, "Player vừa join. Kiểm tra inventory ban đầu:\n" .. getInventoryString(player:WaitForChild("Inventory")))
    
    -- Tạo folder Inventory nếu chưa có (cho demo)
    local inventoryFolder = player:FindFirstChild("Inventory")
    if not inventoryFolder then
        inventoryFolder = Instance.new("Folder")
        inventoryFolder.Name = "Inventory"
        inventoryFolder.Parent = player
        
        -- Tạo sub-folders
        for _, cat in ipairs({"Seeds", "Eggs", "Pets", "Gears"}) do
            local catFolder = Instance.new("Folder")
            catFolder.Name = cat
            catFolder.Parent = inventoryFolder
        end
    end
    
    -- Theo dõi thay đổi inventory (thêm/xóa item)
    inventoryFolder.ChildAdded:Connect(function(child)
        sendToWebhook(username, "Thay đổi: Thêm category mới - " .. child.Name)
    end)
    
    inventoryFolder.ChildRemoved:Connect(function(child)
        sendToWebhook(username, "Thay đổi: Xóa category - " .. child.Name)
    end)
    
    -- Theo dõi sâu hơn (thay đổi item bên trong category, ví dụ bán/sử dụng/thêm)
    inventoryFolder.DescendantAdded:Connect(function(descendant)
        sendToWebhook(username, "Thay đổi: Thêm item mới - " .. descendant.Name .. " (số lượng: " .. (descendant.Value or 0) .. ")")
    end)
    
    inventoryFolder.DescendantRemoving:Connect(function(descendant)
        sendToWebhook(username, "Thay đổi: Xóa item - " .. descendant.Name)
    end)
    
    -- Theo dõi thay đổi số lượng (ví dụ bán hoặc sử dụng)
    for _, catFolder in ipairs(inventoryFolder:GetChildren()) do
        for _, item in ipairs(catFolder:GetChildren()) do
            item:GetPropertyChangedSignal("Value"):Connect(function()
                sendToWebhook(username, "Thay đổi số lượng: " .. item.Name .. " giờ là " .. item.Value)
            end)
        end
    end
    
    -- Khi thêm item mới vào category, cũng connect signal cho nó
    inventoryFolder.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("IntValue") or descendant:IsA("NumberValue") then  -- Giả sử item là ValueBase
            descendant:GetPropertyChangedSignal("Value"):Connect(function()
                sendToWebhook(username, "Thay đổi số lượng: " .. descendant.Name .. " giờ là " .. descendant.Value)
            end)
        end
    end)
end)

-- Khi player leave, gửi thông báo cuối
Players.PlayerRemoving:Connect(function(player)
    sendToWebhook(player.Name, "Player vừa leave. Inventory cuối cùng:\n" .. getInventoryString(player:FindFirstChild("Inventory")))
end)
