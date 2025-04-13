import { Card } from './Card';
import { UserProfile } from "leetcode-query";

interface TasksCardProps {
  data?: any;
  isLoading: boolean;
}

export const TasksCard = ({ data, isLoading }: TasksCardProps) => {
  return (
    <Card title="Today's Tasks" isLoading={isLoading} loadingText="Loading tasks...">
      {data?.todayTasks && data.todayTasks.length > 0 ? (
        data.todayTasks.map((task, index) => (
          <div key={index} className="mb-4">
            <p className="font-semibold">{task.title}</p>
            <p className="text-gray-500">{task.description}</p>
          </div>
        ))
      ) : (
        <p className="text-gray-500">You're all caught up!</p>
      )}
    </Card>
  );
};