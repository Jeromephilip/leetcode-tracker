import { Card } from "./Card";
import { UserProfile } from "leetcode-query";

interface RecentSubmissionsCardProps {
  data?: UserProfile;
  isLoading: boolean;
}

export const RecentSubmissionsCard = ({
  data,
  isLoading,
}: RecentSubmissionsCardProps) => {
  return (
    <Card
      title="Recent Submissions"
      isLoading={isLoading}
      loadingText="Loading submissions..."
    >
      {data?.recentSubmissionList
        ?.filter((submission) => submission.statusDisplay === "Accepted")
        .map((submission) => (
          <div key={submission.title} className="mb-4">
            <p className="font-semibold">{submission.title}</p>
            <p className="text-gray-500">{submission.statusDisplay}</p>
          </div>
        ))}
    </Card>
  );
};
