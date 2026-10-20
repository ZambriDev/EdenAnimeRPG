export type QuestPayload = {
	questId: string,
	name: string,
	progress: number,
	amount: number,
	status: "active" | "ready" | "done",
	reward: { XP: number, Gold: number },
}

return {}