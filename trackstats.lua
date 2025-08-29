local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Webhook URL từ bạn cung cấp
local WEBHOOK_URL = "https://discord.com/api/webhooks/1410899635135844433/XRFNK82iZC-VzwyJ-L6Da0u6yEqJKHJHzKUQtrn5NU2EM69OYy3UB2ouQRuCbPq_wiCg"

-- Queue để tránh rate limit
local requestQueue = {}
local isProcessingQueue = false

-- Hàm gửi webhook với embed
local function sendToWebhook(username, message, color)
    local data = {
        embeds = {{
            title = "Inventory Update for " .. username,
            description = message,
            color = color or 0x00FF00, -- Màu xanh lá mặc định
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ") -- Thời gian UTC
        }},
        username = "Spidey Bot",
        avatar_url = "https://example.com/spideybot.png" -- Optional
    }
    local jsonData = HttpService:JSONEncode(data)
    
    table.insert(requestQueue, jsonData)
    processQueue() -- Gọi hàm xử lý queue
end -- Kết thúc hàm sendToWebhook

-- Hàm xử lý queue để tránh rate limit
local function processQueue()
    if isProcessingQueue or #requestQueue == 0 then return end
    isProcessingQueue = true
    
    local jsonData = requestQueue[1]
    local success, err = pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, jsonData, Enum.HttpContentType.ApplicationJson)
    end)
    
    if success then
        print("Webhook gửi thành công: " .. jsonData)
        table.remove(requestQueue, 1)
    else
        warn("Lỗi gửi webhook: " .. tostring(err))
    end
    
    isProcessingQueue = false
    if #requestQueue > 0 then
        wait(2) -- Delay 2s để tránh rate limit
        processQueue()
    end
end -- Kết thúc hàm processQueue

-- Hàm lấy inventory dưới dạng string
local function getInventoryString(inventoryFolder)
    if not inventoryFolder then
        return "Inventory không tồn tại."
    end
    
    local invStr = ""
    for _, category in ipairs({"Seeds", "Eggs", "Pets", "Gears"}) do
        local catFolder = inventoryFolder:FindFirstChild(category)
        if catFolder then
            invStr = invStr .. "**" .. category .. ":**\n"
            for _, item in ipairs(catFolder:GetChildren()) do
                local quantity = item:IsA("ValueBase") and item.Value or 0
                invStr = invStr .. "- " .. item.Name .. ": " .. quantity .. "\n"
            end
            invStr = invStr .. "\n"
        end
    end
    
    return invStr ~= "" and invStr or "Inventory rỗng."
end -- Kết thúc hàm getInventoryString

-- Khi player join
Players.PlayerAdded:Connect(function(player)
    local username = player.Name
    print("Player joined: " .. username)
    
    -- Chờ Inventory được tạo
    local inventoryFolder = player:WaitForChild("Inventory", 5)
    if not inventoryFolder then
        inventoryFolder = Instance.new("Folder")
        inventoryFolder.Name = "Inventory"
        inventoryFolder.Parent = player
        print("Tạo mới Inventory cho " .. username)
        
        for _, cat in ipairs({"Seeds", "Eggs", "Pets", "Gears"}) do
            local catFolder = Instance.new("Folder")
            catFolder.Name = cat
            catFolder.Parent = inventoryFolder
        end
    end
    
    -- Gửi inventory ban đầu
    sendToWebhook(username, "Player vừa join. Inventory ban đầu:\n" .. getInventoryString(inventoryFolder), 0x00FF00)
    
    -- Theo dõi thay đổi inventory
    inventoryFolder.ChildAdded:Connect(function(child)
        print("Thêm category: " .. child.Name)
        sendToWebhook(username, "Thay đổi: Thêm category mới - " .. child.Name, 0xFFFF00) -- Màu vàng
    end)
    
    inventoryFolder.ChildRemoved:Connect(function(child)
        print("Xóa category: " .. child.Name)
        sendToWebhook(username, "Thay đổi: Xóa category - " .. child.Name, 0xFF0000) -- Màu đỏ
    end)
    
    inventoryFolder.DescendantAdded:Connect(function(descendant)
        local quantity = descendant:IsA("ValueBase") and descendant.Value or 0
        print("Thêm item: " .. descendant.Name .. " (số lượng: " .. quantity .. ")")
        sendToWebhook(username, "Thay đổi: Thêm item mới - " .. descendant.Name .. " (số lượng: " .. quantity .. ")", 0x00FFFF) -- Màu cyan
    end)
    
    inventoryFolder.DescendantRemoving:Connect(function(descendant)
        print("Xóa item: " .. descendant.Name)
        sendToWebhook(username, "Thay đổi: Xóa item - " .. descendant.Name, 0xFF0000) -- Màu đỏ
    end)
    
    -- Theo dõi thay đổi số lượng
    for _, catFolder in ipairs(inventoryFolder:GetChildren()) do
        for _, item in ipairs(catFolder:GetChildren()) do
            if item:IsA("ValueBase") then
                item:GetPropertyChangedSignal("Value"):Connect(function()
                    print("Số lượng thay đổi: " .. item.Name .. " = " .. item.Value)
                    sendToWebhook(username, "Thay đổi số lượng: " .. item.Name .. " giờ là " .. item.Value, 0xFFA500) -- Màu cam
                end)
            end
        end
    end
    
    inventoryFolder.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ValueBase") then
            descendant:GetPropertyChangedSignal("Value"):Connect(function()
                print("Số lượng thay đổi: " .. descendant.Name .. " = " .. descendant.Value)
                sendToWebhook(username, "Thay đổi số lượng: " .. descendant.Name .. " giờ là " .. descendant.Value, 0xFFA500) -- Màu cam
            end)
        end
    end)
end) -- Kết thúc PlayerAdded

-- Khi player leave
Players.PlayerRemoving:Connect(function(player)
    local inventoryFolder = player:FindFirstChild("Inventory")
    print("Player leave: " .. player.Name)
    sendToWebhook(player.Name, "Player vừa leave. Inventory cuối cùng:\n" .. getInventoryString(inventoryFolder), 0x808080) -- Màu xám
end) -- Kết thúc PlayerRemoving
