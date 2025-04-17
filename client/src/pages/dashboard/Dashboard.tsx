import { RecentSubmissionsCard } from "./components/card/RecentSubmissionsCard";
import { TasksCard } from "./components/card/TasksCard";
import { useLeetcodeUserDetails } from "./hooks/useLeetcodeDetails";
import { useDueReviews } from "./hooks/useDueReviews";
import { Flex, Spin } from "antd";
import { LoadingOutlined } from '@ant-design/icons';


const Dashboard = () => {
  const { data, isLoading } = useLeetcodeUserDetails("jerodahero");

  const { data: tasks, isLoading: isReviewLoading } = useDueReviews();

  console.log(tasks);

  return (
    <div className="min-h-screen bg-gray-100 p-8">
      <div className="max-w-6xl mx-auto">
        <h1 className="text-2xl font-bold mb-6">📊 LeetCode Tracker</h1>
        {isLoading || isReviewLoading ? (
          <div className="flex justify-center items-center min-h-[50vh]">
            <Flex align="center">
              <Spin indicator={<LoadingOutlined spin />} size="large" />
            </Flex>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <RecentSubmissionsCard data={data} isLoading={isLoading} />
            <TasksCard data={tasks} isLoading={isReviewLoading} />
          </div>
        )}
      </div>
    </div>
  );
};

export default Dashboard;
