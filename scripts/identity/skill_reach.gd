class_name SkillReach
extends RefCounted
## How far from its foe a sinner should stand to use a skill the way the game built it.
## A skill that dashes at its foe sets its own distance (its moves stop where the game says).
## Until its first dash it plays from where it stands, and the effects it puts in front of
## itself there (a magic seal, a muzzle flash, a swing) are built for a foe beyond them: across
## the roster they sit up to ~160 px out. The game keeps its clash spacing in code, not data,
## so the stand-off is read off those effects: the foe goes MARGIN past the furthest of them.

## px between an opening effect's centre and the foe's: enough for a seal to sit between the
## two, while a swing's arc still sweeps into the foe.
const MARGIN := 70.0


## The stand-off for `skill` (px from the sinner's feet to the foe's centre, sideways): past
## its opening effects, and never less than `least`.
static func stand_off(identity: IdentityData, skill: SkillData, least: float) -> float:
	var distance := least
	for timeline in skill.coin_timelines:
		var dash_at := timeline.first_dash_time()
		for cue in timeline.fx_cues:
			if cue.time >= dash_at:
				break
			var effect := identity.effect(cue.effect_name)
			if effect and not effect.is_on_target():
				distance = maxf(distance, effect.forward_reach() + MARGIN)
		if dash_at < INF:
			break
	return distance
