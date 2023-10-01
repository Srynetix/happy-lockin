extends AudioStreamPlayer

const THEME1 := preload("res://audio/theme1.ogg")
const INTRO := preload("res://audio/intro.ogg")

enum Track {
    Theme1,
    Intro
}

func set_track(track: Track) -> void:
    stop()

    if track == Track.Theme1:
        stream = THEME1
    else:
        stream = INTRO

func fade_in() -> void:
    volume_db = -INF
    $AnimationPlayer.play("fade_in")
    await $AnimationPlayer.animation_finished

func fade_out() -> void:
    $AnimationPlayer.play("fade_out")
    await $AnimationPlayer.animation_finished

func fade_out_and_stop() -> void:
    await fade_out()
    stop()
