-- Actual event/deferred handlers and retry policy, not a copy of their logic.
local QA=QuestAnnounce
local event=QA.scripts.OnEvent
assert(type(event)=="function")
local soundCount=0
local originalSound=QA.PlayConfiguredSound
QA.PlayConfiguredSound=function(_,kind) if kind=="turnin" then soundCount=soundCount+1 end end
function GetQuestID() return 123 end
event(QA,"QUEST_COMPLETE")
event(QA,"QUEST_TURNED_IN",123)
assert(soundCount==0, "turn-in must be deferred")
TEST_FLUSH_TIMERS()
assert(soundCount==1 and QA.lastManualTurnInIntent==nil)
-- A cinematic finishing or being cancelled must not cause another turn-in sound.
event(QA,"CINEMATIC_STOP")
event(QA,"QUEST_TURNED_IN",123)
TEST_FLUSH_TIMERS()
assert(soundCount==1)
TEST_TIME=TEST_TIME+11
QA.lastManualTurnInIntent={time=TEST_TIME,questID=124}
event(QA,"QUEST_TURNED_IN",125)
TEST_FLUSH_TIMERS()
assert(soundCount==1, "mismatched quest ID must not play a manual turn-in sound")
QA.lastManualTurnInIntent=nil
QA.db.profile.settings.playTurnInOnAutoTurnIn=false
event(QA,"QUEST_TURNED_IN",126)
TEST_FLUSH_TIMERS()
assert(soundCount==1)
QA.db.profile.settings.playTurnInOnAutoTurnIn=true
event(QA,"QUEST_TURNED_IN",127)
TEST_FLUSH_TIMERS()
assert(soundCount==2)
QA.db.profile.settings.playTurnInOnAutoTurnIn=false
QA.PlayConfiguredSound=originalSound

local originalDispatch=QA.DispatchChatOutputs
local replayCount=0
QA.DispatchChatOutputs=function(_,msg,allowQueue)
    assert(msg=="latest" and allowQueue==false)
    replayCount=replayCount+1
end
QA:QueuePendingCombatChatMessage("first")
QA:QueuePendingCombatChatMessage("latest")
TEST_COMBAT=true
QA:FlushPendingCombatChatMessage()
assert(replayCount==0 and QA.pendingCombatChatMessage==nil)
-- A retry is consumed even if restrictions still apply; it must not loop.
QA:QueuePendingCombatChatMessage("latest")
TEST_COMBAT=false
TEST_TIME=TEST_TIME+2
event(QA,"PLAYER_REGEN_ENABLED")
assert(replayCount==1 and QA.pendingCombatChatMessage==nil)
event(QA,"PLAYER_REGEN_ENABLED")
assert(replayCount==1)
QA:QueuePendingCombatChatMessage("latest")
TEST_TIME=TEST_TIME+10.001
QA:FlushPendingCombatChatMessage()
assert(replayCount==1)
-- Preserve all former queue-policy boundary cases using the real Lua handler.
local baseTime=TEST_TIME
for _,age in ipairs({0,10,10.001,-0.001}) do
    TEST_TIME=baseTime
    QA:QueuePendingCombatChatMessage("latest")
    TEST_TIME=baseTime+age
    local before=replayCount
    QA:FlushPendingCombatChatMessage()
    assert(replayCount==before+((age>=0 and age<=10) and 1 or 0))
    assert(QA.pendingCombatChatMessage==nil)
end
QA.DispatchChatOutputs=originalDispatch
