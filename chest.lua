--[[
    BLOX FRUITS AUTO CHEST - OPTIMIZED
    - Tween Mượt (Bypass Anti-cheat cơ bản)
    - Auto Tìm Rương Gần Nhất
    - Gom rương toàn map (Sea 1, 2, 3 đều hoạt động)
]]

local Settings = {
    Speed = 350,       -- Tốc độ bay (Blox Fruits map rộng nên để cao chút)
    TweenDelay = 0.1,  -- Độ trễ xử lý
    AutoFarm = true    -- Bật/Tắt
}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Local Player
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Danh sách tên rương trong Blox Fruits
local ChestNames = {
    "Chest1", -- Rương Bạc
    "Chest2", -- Rương Vàng
    "Chest3"  -- Rương Kim Cương
}

-- Hàm giữ nhân vật lơ lửng (Bypass rơi tự do/kéo lại)
local function SetNoClip(state)
    for _, part in pairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
    -- Giữ vận tốc bằng 0 để không bị trọng lực kéo xuống khi Tween
    if state and HumanoidRootPart then
        HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
    end
end

-- Hàm tìm rương gần nhất
function GetNearestChest()
    local TargetDistance = math.huge
    local TargetChest = nil

    -- Blox Fruits thường để rương rải rác trong Workspace hoặc các folder Map
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Part") or v:IsA("MeshPart") then
            -- Kiểm tra xem tên có khớp với danh sách rương không
            local IsChest = false
            for _, name in ipairs(ChestNames) do
                if v.Name == name or v.Parent.Name == name then 
                    IsChest = true 
                    break 
                end
            end

            if IsChest then
                -- Nếu là Model thì lấy RootPart, nếu là Part thì lấy chính nó
                local ChestRoot = v
                -- Kiểm tra rương đã mở chưa (Trong Blox Fruits, rương mở xong thường biến mất hoặc Transparency = 1)
                if ChestRoot.Transparency < 1 then
                    local Dist = (HumanoidRootPart.Position - ChestRoot.Position).Magnitude
                    if Dist < TargetDistance then
                        TargetDistance = Dist
                        TargetChest = ChestRoot
                    end
                end
            end
        end
    end
    return TargetChest
end

-- Hàm bay (Tween)
local CurrentTween = nil
function TweenTo(TargetPosition)
    if not HumanoidRootPart then return end

    local Distance = (HumanoidRootPart.Position - TargetPosition).Magnitude
    local Time = Distance / Settings.Speed

    local TweenInfo = TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    
    -- Hủy tween cũ nếu đang chạy
    if CurrentTween then CurrentTween:Cancel() end

    CurrentTween = TweenService:Create(HumanoidRootPart, TweenInfo, {CFrame = CFrame.new(TargetPosition)})
    CurrentTween:Play()
    
    return CurrentTween, Time
end

-- Vòng lặp chính
spawn(function()
    while Settings.AutoFarm do
        task.wait() -- Tránh crash game
        pcall(function()
            -- Cập nhật nhân vật
            if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
                Character = Player.Character or Player.CharacterAdded:Wait()
                HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                return
            end

            -- Bật chế độ bay/xuyên tường
            SetNoClip(true)

            local Chest = GetNearestChest()

            if Chest then
                -- Tính toán vị trí đến (Nên đến ngay chính giữa rương)
                local TargetPos = Chest.Position
                
                -- Bắt đầu Tween
                local Tween, EstTime = TweenTo(TargetPos)
                
                -- Vòng lặp đợi đến nơi
                local Arrived = false
                local StartTime = tick()
                
                repeat
                    task.wait()
                    SetNoClip(true) -- Liên tục giữ trạng thái xuyên tường
                    
                    -- Kiểm tra nếu rương biến mất giữa đường
                    if not Chest or not Chest.Parent or Chest.Transparency >= 1 then
                        if CurrentTween then CurrentTween:Cancel() end
                        break
                    end
                    
                    -- Kiểm tra khoảng cách
                    if (HumanoidRootPart.Position - TargetPos).Magnitude < 10 then
                        Arrived = true
                    end
                until Arrived or (tick() - StartTime) > (EstTime + 2) -- Timeout an toàn
                
                if Arrived then
                    if CurrentTween then CurrentTween:Cancel() end
                    
                    -- == PHẦN REMOTE EVENT / TOUCH ==
                    -- Trong Blox Fruits, rương không có RemoteEvent dạng "Click".
                    -- Sự kiện nhận rương được kích hoạt bởi TouchInterest.
                    -- firetouchinterest giả lập việc Server nhận tín hiệu va chạm.
                    firetouchinterest(HumanoidRootPart, Chest, 0) -- Touch Start
                    firetouchinterest(HumanoidRootPart, Chest, 1) -- Touch End
                    
                    task.wait(0.2) -- Đợi một chút để server xử lý tiền
                end
            else
                -- Nếu hết rương hoặc map chưa load kịp
                if CurrentTween then CurrentTween:Cancel() end
                task.wait(1)
            end
        end)
    end
    -- Tắt noclip khi dừng script
    SetNoClip(false)
end)
