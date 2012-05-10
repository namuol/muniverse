HUD_X = 10
HUD_Y = 10
HUD_BAR_W = 4
HUD_BAR_H = 50
HUD_SHIELD_X = 0
HUD_SHIELD_Y = 0

HUD_FTL_X = 20
HUD_FTL_Y = 0
class Hud
  group: 'hud'
  constructor: ->
    @h = HUD_BAR_H
    @tick = 0
  blit: ->
    c = gbox.getBufferContext()
    return if not c

    ####################################################
    # SHIELD LEVEL 
    c.fillStyle = 'rgba(255,255,255,0.5)'
    c.fillRect(
      Math.round(HUD_X + HUD_SHIELD_X + 2),
      Math.round(HUD_Y + HUD_SHIELD_Y + 9),
      HUD_BAR_W,
      HUD_BAR_H
    )

    h_diff = 0
    if player.shields > 0
      @target_h = HUD_BAR_H * player.shields/player.shields_max
      h_diff = (@target_h-@h)*0.05

    extrax = 0
    extray = 0
    if (player.shields <= 1) and (player.shields > 0)
      c.fillStyle = 'rgba(255,0,0,1)'
      extrax = frand(-1,1)
      extray = frand(-1,1)
    else
      c.fillStyle = 'rgba(255,255,255,1)'
    gbox.blitText c,
      font: 'small'
      text: 'S'
      dx:Math.round(HUD_X + HUD_SHIELD_X + frand(-5,5)*h_diff + extrax)
      dy:Math.round(HUD_Y + HUD_SHIELD_Y + frand(-5,5)*h_diff + extray)
      dw:16
      dh:16


    if player.shields > 0
      @h += h_diff

      c.fillRect(
        Math.round(HUD_X + HUD_SHIELD_X + 2 + extrax),
        Math.round(HUD_Y + HUD_SHIELD_Y + 9 + extrax),
        HUD_BAR_W,
        Math.round(@h)
      )

    # SHIELD LEVEL 
    ####################################################

    ####################################################
    # FTL STATUS -- CAN I FLEE?
    
    # Since this can be an expensive operation, we only check every tenth frame:
    if (@tick % 10 == 0)
      @can_flee = player.can_flee()

    if @can_flee
      ftl_alpha = 1.0
    else
      ftl_alpha = 0.25

    gbox.blitText c,
      font: 'small'
      text: 'FTL'
      dx:Math.round(HUD_X + HUD_FTL_X)
      dy:Math.round(HUD_Y + HUD_FTL_Y)
      dw:16*3
      dh:16
      alpha: ftl_alpha

    # FTL STATUS -- CAN I FLEE?
    ####################################################

    
    ++@tick
