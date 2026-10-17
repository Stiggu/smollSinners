class_name ClashLayout
extends RefCounted
## Where everything goes in a clash against an icon, in overlay coordinates: the sinner on
## the screen-centre side of the icon with the icon level with its chest, and both badges
## above their fighters, ribbons pointing away from each other. A clash only starts where
## this fits as laid out (fits()): badges are never moved to make room.

## px between the sinner's feet and the icon's centre, sideways, at the least: a skill whose
## opening effects reach further wants more (SkillReach)
const STAND_OFF := 130.0
const FEET_BELOW_ICON := 90.0  ## the icon ends up level with the sinner's chest
const HIGHEST_FEET := 240.0  ## any higher and the sinner's badge wouldn't fit above it
const ICON_BADGE_OFFSET := Vector2(0, -95)  ## the icon's badge, from the icon's centre
## How far a badge reaches from its centre, laid out with its ribbon running right
## (mirrored when it runs left): coins and tab above, attack icon below, and behind it the
## face's glow. Forward it reaches its ribbon's end, plus RIBBON_TIP. (Each round's count
## sits between the badges, inside the footprint.)
const BADGE_UP := 58.0
const BADGE_DOWN := 48.0
const BADGE_BACK := 34.0
const RIBBON_TIP := 10.0
const SCREEN_MARGIN := 4.0  ## the least gap between a clash's badges and the overlay's edges
const FEET_MARGIN := 40.0  ## the least gap between the sinner's feet and the overlay's edges
const SINNER_BOX := Rect2(-80, -200, 160, 230)  ## roughly the sinner, from its feet

var side := 1  ## +1: the sinner stands right of the icon
var feet := Vector2.ZERO  ## where the sinner stands
var sinner_badge := Vector2.ZERO  ## the centre of the sinner's badge
var icon_badge := Vector2.ZERO  ## ... and of the icon's
var icon_rect := Rect2()


## The layout against an icon at `icon_rect` (overlay coordinates). floor_y: where sinners
## stand; badge_offset: a sinner's badge from its feet; stand_off: px from the sinner's feet
## to the icon's centre, sideways (see STAND_OFF).
static func around(rect: Rect2, overlay_size: Vector2, floor_y: float, badge_offset: Vector2,
		stand_off := STAND_OFF) -> ClashLayout:
	var layout := ClashLayout.new()
	var icon_center := rect.get_center()
	layout.icon_rect = rect
	layout.side = 1 if icon_center.x < overlay_size.x / 2.0 else -1
	layout.feet = Vector2(icon_center.x + layout.side * stand_off,
			clampf(icon_center.y + FEET_BELOW_ICON, HIGHEST_FEET, floor_y))
	layout.sinner_badge = (layout.feet + badge_offset).round()
	layout.icon_badge = (icon_center + ICON_BADGE_OFFSET).round()
	return layout


## Both badges whole on the overlay and room for the sinner to stand. sinner_ribbon,
## icon_ribbon: how far each badge's ribbon reaches (ClashBadge.ribbon_end()).
func fits(overlay_size: Vector2, sinner_ribbon: float, icon_ribbon: float) -> bool:
	var screen := Rect2(Vector2.ZERO, overlay_size).grow(-SCREEN_MARGIN)
	return (screen.encloses(badge_box(sinner_badge, side, sinner_ribbon))
			and screen.encloses(badge_box(icon_badge, -side, icon_ribbon))
			and feet.x >= FEET_MARGIN and feet.x <= overlay_size.x - FEET_MARGIN)


## The part of the overlay the clash takes up: the icon, the sinner's spot and both badges.
## Clashes running at once keep these apart.
func footprint(sinner_ribbon: float, icon_ribbon: float) -> Rect2:
	return (icon_rect
			.merge(Rect2(feet + SINNER_BOX.position, SINNER_BOX.size))
			.merge(badge_box(sinner_badge, side, sinner_ribbon))
			.merge(badge_box(icon_badge, -side, icon_ribbon)))


## A badge's whole extent, centred at `center` with its ribbon (`ribbon` long) running outward.
static func badge_box(center: Vector2, outward: int, ribbon: float) -> Rect2:
	var forward := ribbon + RIBBON_TIP
	var left := -BADGE_BACK if outward > 0 else -forward
	var right := forward if outward > 0 else BADGE_BACK
	return Rect2(center.x + left, center.y - BADGE_UP, right - left, BADGE_UP + BADGE_DOWN)
