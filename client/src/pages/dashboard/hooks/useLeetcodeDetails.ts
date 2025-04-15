import { useQuery } from "@tanstack/react-query";
import { UserProfile } from "leetcode-query";

const fetchLeetCodeUser = async (username: string): Promise<UserProfile> => {
  const res = await fetch(`http://localhost:4000/api/user/${username}`, {
    method: 'GET',
    credentials: 'include'
  });

  if (!res.ok) throw new Error("Network response was not ok");
  return res.json();
};

export const useLeetcodeUserDetails = (username: string) => {
  return useQuery<UserProfile>({
    queryKey: ["leetcodeUser", username],
    queryFn: () => fetchLeetCodeUser(username),
  });
};
