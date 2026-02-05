# eu não sei programar então eu dependi muito do GEMINI pra isso
# pro codigo funcionar é só adicionar ele à um retângulo, futuramente vou upar na workshop da steam pra facilitar
  
local BASE_URL = "https://raw.githubusercontent.com/otowm/MTG-PTBR/refs/heads/main/"
local BACK_URL = "https://steamusercontent-a.akamaihd.net/ugc/15242328898220226967/35EF6E87970E2A5D6581E7D96A99F8A575B7A15F/"
local FOLDERS = {"pt", "en"}

function onLoad()
    self.setName("Tradutor Automático")
    local sScale = self.getScale()

    self.createButton({
        click_function = "start_mega_translation",
        function_owner = self,
        label          = "TRADUZIR",
        position       = {0, 0.5, 0.65}, 
        scale          = {0.5/sScale[1], 0.5/sScale[2], 0.5/sScale[3]},
        width          = 4000,
        height         = 800,
        font_size      = 500,
        color          = {0.1, 0.1, 0.1},
        font_color     = {1, 1, 1}
    })
end

function find_object_on_top()
    local hits = Physics.cast({
        origin = self.getPosition(),
        direction = {0, 1, 0},
        type = 3,
        size = self.getBounds().size,
        max_distance = 0.5
    })
    for _, hit in ipairs(hits) do
        if hit.hit_object != self and (hit.hit_object.tag == "Deck" or hit.hit_object.tag == "Card") then
            return hit.hit_object
        end
    end
    return nil
end

function start_mega_translation()
    local obj = find_object_on_top()
    if obj then
        process_step()
    else
        broadcastToAll("Coloque o Deck ou Carta em cima!", {1, 0.8, 0})
    end
end

function process_step()
    local obj = find_object_on_top()
    
    if obj == nil then
        broadcastToAll("✓ Processo finalizado!", {0, 1, 0})
        return
    end

    local pos = self.getPosition()
    -- ALTERAÇÃO AQUI: Z - 6 move para "baixo" (direção do jogador)
    -- X fica em 0 (alinhado verticalmente com o quadrado)
    local target_pos = {pos.x, pos.y + 1, pos.z - 6}

    if obj.tag == "Deck" then
        obj.takeObject({
            position          = target_pos,
            rotation          = {0, 180, 0},
            smooth            = true,
            callback_function = function(card)
                process_card(card)
                Wait.time(function() process_step() end, 0.7)
            end
        })
    elseif obj.tag == "Card" then
        obj.setPositionSmooth(target_pos)
        obj.setRotationSmooth({0, 180, 0})
        process_card(obj)
        Wait.time(function() process_step() end, 1.0)
    end
end

function get_clean_name(str)
    if not str or str == "" then return "" end
    local name = str:match("([^\n\r]+)")
    if name then name = name:match("([^—]+)") end
    if name then name = name:gsub("’", "'") end
    return name and name:match("^%s*(.-)%s*$") or ""
end

function process_card(target)
    if target == nil or target.isDestroyed() then return end
    local name = get_clean_name(target.getName())
    if name == "" then return end
    
    local urlName = name:gsub(" ", "%%20")

    local function try_f(idx)
        if idx > #FOLDERS then return end
        local u = BASE_URL .. FOLDERS[idx] .. "/" .. urlName .. ".png"
        
        WebRequest.get(u, function(req)
            if target == nil or target.isDestroyed() then return end
            if req.response_code == 200 then
                local c = target.getCustomObject()
                c.face = u
                c.back = BACK_URL
                target.setCustomObject(c)
                target.reload()
            else
                try_f(idx + 1)
            end
        end)
    end
    try_f(1)
end
