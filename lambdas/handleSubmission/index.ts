import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";

type Submission = {
  problemId: string;
  solvedAt: string;
};

const reviewIntervals = [1, 3, 7, 14, 30];

const getReviewsDueToday = (
  submissions: Submission[]
): Submission[] => {
  const today = new Date().toISOString().split("T")[0];
  console.log(`Today is: ${today}`);

  return submissions
    .filter(({ solvedAt }) => {
      const solvedDate = new Date(solvedAt);

      const reviewDates = reviewIntervals.map((days) => {
        const date = new Date(solvedDate);
        date.setDate(date.getDate() + days);
        return date.toISOString().split("T")[0];
      });

      console.log(`Review dates for ${solvedAt}: ${reviewDates.join(", ")}`);
      return reviewDates.includes(today);
    })
    .map((s) => ({ problemId: s.problemId, solvedAt: s.solvedAt }));
};

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  console.log("Lambda invoked");
  console.log("Raw event body:", event.body);

  try {
    const body = JSON.parse(event.body || "{}") as {
      submissions: Submission[];
    };
    console.log("Parsed submissions:", body.submissions);

    if (!Array.isArray(body.submissions)) {
      console.warn("Submissions array is invalid");
      return {
        statusCode: 400,
        body: JSON.stringify({
          error: 'Missing or invalid "submissions" array',
        }),
      };
    }

    const dueProblems = getReviewsDueToday(body.submissions);
    console.log("Due problems today:", dueProblems);

    return {
      statusCode: 200,
      body: JSON.stringify({ dueProblems }),
    };
  } catch (err) {
    console.error("Error occurred:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: "Internal server error",
        message: (err as Error).message,
      }),
    };
  }
};
