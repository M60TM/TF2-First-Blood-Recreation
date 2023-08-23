# [TF2] First-Blood-Recreation
Simple plugin that recreation of arena first-blood with some ConVars.

## ConVar
```
tf_fbr_enabled(def = "1"): Enable first blood recreation plugin. If you disable it, plugin will reenable tf_arena_first_blood.
tf_fbr_check_dead_ringer(def = "1"): If set to 1, it doesn't consider dead ringer kill as real death.
tf_fbr_duration(def = "5.0"): Adjusting first blood critical duration.
tf_fbr_limit(def = "0.0"): The Time limit of getting first blood critical. It is ignored when set to 0.0.
```

## Note
* Don't use this with plugins that need to set `tf_arena_first_blood`. This plugin automatically toggles it when `tf_fbr_enabled`'s value is changed.

----

## Building

This project is configured for building via [Ninja][]; see `BUILD.md` for detailed
instructions on how to build it.

If you'd like to use the build system for your own projects,
[the template is available here](https://github.com/nosoop/NinjaBuild-SMPlugin).

[Ninja]: https://ninja-build.org/
