import { useEffect, useState } from "react";
import { Card } from "./Card";
import { useMutation } from "@tanstack/react-query";

export interface ReviewTask {
  id: string;
  problemId: string;
  reviewed: boolean;
  reviewDate: string;
}

interface TasksCardProps {
  data?: ReviewTask[];
  isLoading: boolean;
}

export const TasksCard = ({ data, isLoading }: TasksCardProps) => {
  const [tasks, setTasks] = useState<ReviewTask[]>([]);

  useEffect(() => {
    if (data) setTasks(data);
  }, [data]);

  const { mutate: markReviewed } = useMutation({
    mutationFn: async (id: string) => {
      await fetch(`/api/review/${id}`, {
        method: "PATCH",
        credentials: "include",
      });
    },
    onSuccess: (_, id) => {
      const taskElement = document.getElementById(`task-${id}`);
      if (taskElement) {
        taskElement.classList.add("opacity-0", "translate-x-4");
        setTimeout(() => {
          setTasks((prev) => prev.filter((task) => task.id !== id));
        }, 300);
      }
    },
  });

  return (
    <Card
      title="Today's Tasks"
      isLoading={isLoading}
      loadingText="Loading tasks..."
    >
      <div className="space-y-1 overflow-x-hidden">
        {tasks.length > 0 ? (
          tasks.map((task) => (
            <div
              key={task.id}
              id={`task-${task.id}`}
              className="flex items-start justify-between transition-all duration-300 ease-in-out bg-white/5 p-3 rounded-md hover:bg-white/10 gap-4 overflow-hidden"
            >
              <div className="min-w-0 flex-1">
                <p className="font-semibold text-black break-words truncate">
                  {task.problemId}
                </p>
                <p className="text-sm text-gray-400 break-words">
                  Last reviewed at:{" "}
                  <span className="font-mono">{task.reviewDate}</span>
                </p>
              </div>
              <input
                type="checkbox"
                onChange={() => markReviewed(task.id)}
                className="w-5 h-5 rounded border-gray-600 accent-green-500 transition-colors shrink-0"
              />
            </div>
          ))
        ) : (
          <p className="text-gray-400 text-sm text-center">
            You're all caught up! 🎉
          </p>
        )}
      </div>
    </Card>
  );
};
