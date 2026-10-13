// Collides with everything.
::COLLISION_GROUP_NONE <- 0

// Collides with nothing but world and static stuff.
::COLLISION_GROUP_DEBRIS <- 1

// Same as debris, but hits triggers.
::COLLISION_GROUP_DEBRIS_TRIGGER <- 2

// Collides with everything except other interactive debris or debris.
::COLLISION_GROUP_INTERACTIVE_DEBRIS <- 3

// Collides with everything except interactive debris or debris.
::COLLISION_GROUP_INTERACTIVE <- 4

// Used by players, ignores PASSABLE_DOOR.
::COLLISION_GROUP_PLAYER <- 5

// Breakable glass, ignores same group and NPC line-of-sight.
::COLLISION_GROUP_BREAKABLE_GLASS <- 6

// Driveable vehicles, always collides with VEHICLE_CLIP.
::COLLISION_GROUP_VEHICLE <- 7

// Player movement collision.
::COLLISION_GROUP_PLAYER_MOVEMENT <- 8

// Used by NPCs, always collides with DOOR_BLOCKER.
::COLLISION_GROUP_NPC <- 9

// Entities inside vehicles, no collisions.
::COLLISION_GROUP_IN_VEHICLE <- 10

// Weapons, including dropped ones.
::COLLISION_GROUP_WEAPON <- 11

// Only collides with VEHICLE.
::COLLISION_GROUP_VEHICLE_CLIP <- 12

// Projectiles, ignore other projectiles.
::COLLISION_GROUP_PROJECTILE <- 13

// Blocks NPCs, may collide with some projectiles.
::COLLISION_GROUP_DOOR_BLOCKER <- 14

// Passable doors, allows players through.
::COLLISION_GROUP_PASSABLE_DOOR <- 15

// Dissolved entities, only collide with NONE.
::COLLISION_GROUP_DISSOLVING <- 16

// Pushes props away from the player.
::COLLISION_GROUP_PUSHAWAY <- 17

// NPCs potentially stuck in a player.
::COLLISION_GROUP_NPC_ACTOR <- 18

// NPCs in scripted sequences with collisions disabled.
::COLLISION_GROUP_NPC_SCRIPTED <- 19

// It doesn't seem to be used anywhere in the engine.
::COLLISION_GROUP_PZ_CLIP <- 20

// Solid only to the camera's test trace (Outdated).
::COLLISION_GROUP_CAMERA_SOLID <- 21

// Solid only to the placement tool's test trace (Outdated).
::COLLISION_GROUP_PLACEMENT_SOLID <- 22

// Held objects that shouldn't collide with players.
::COLLISION_GROUP_PLAYER_HELD <- 23

// Cubes need a collision group that acts roughly like COLLISION_GROUP_NONE but doesn't collide with debris or interactive.
::COLLISION_GROUP_WEIGHTED_CUBE <- 24

// No collision at all.
::SOLID_NONE <- 0

// Uses Quake Physics engine.
::SOLID_BSP <- 1

// Uses an axis-aligned bounding box (AABB).
::SOLID_AABB <- 2

// Uses an oriented bounding box (OBB).
::SOLID_OBB <- 3

// Uses an OBB constrained to yaw rotation.
::SOLID_OBB_YAW <- 4

// Custom/test solid type.
::SOLID_CUSTOM <- 5

// Uses VPhysics engine for realistic physics.
::SOLID_VPHYSICS <- 6