class_name CoinStep
extends RefCounted
## One timeline of a skill performance and the coin it belongs to (see plan()).

var coin := 0  ## the coin's index
var timeline: Timeline


func _init(coin_index: int, coin_timeline: Timeline) -> void:
	coin = coin_index
	timeline = coin_timeline


## Which of a skill's timelines play for its first `coins_used` of `total_coins` coins, in
## order. Usually one timeline per coin, but not always: timelines without hits before the
## first hit are the first coin's run-up, those after the last hit are the finish (they go
## with the last coin played), extra ones with hits belong to the last coin, and when there
## are too few the last one with hits repeats.
static func plan(timelines: Array[Timeline], total_coins: int, coins_used: int) -> Array[CoinStep]:
	var steps: Array[CoinStep] = []
	if timelines.is_empty():
		return steps
	total_coins = maxi(total_coins, 1)
	coins_used = clampi(coins_used, 1, total_coins)
	var hitting := _indices_with_hits(timelines)
	var first_hit: int = hitting[0]
	var last_hit: int = hitting[-1]

	var per_coin: Array[Array] = []
	for i in total_coins:
		per_coin.append([])
	var finish: Array[Timeline] = []
	var coin := 0
	for i in timelines.size():
		if i <= first_hit:
			per_coin[0].append(timelines[i])
		elif i > last_hit:
			finish.append(timelines[i])
		else:
			coin = mini(coin + 1, total_coins - 1)
			per_coin[coin].append(timelines[i])

	for i in coins_used:
		if per_coin[i].is_empty():
			per_coin[i] = [timelines[last_hit]]
		for timeline: Timeline in per_coin[i]:
			steps.append(CoinStep.new(i, timeline))
	for timeline in finish:
		steps.append(CoinStep.new(coins_used - 1, timeline))
	return steps


## The timelines that have hits; all of them if none has.
static func _indices_with_hits(timelines: Array[Timeline]) -> Array[int]:
	var found: Array[int] = []
	for i in timelines.size():
		if timelines[i].has_hits():
			found.append(i)
	if found.is_empty():
		found.assign(range(timelines.size()))
	return found
