import { useEffect, useState } from "react";
import { supabase } from "../lib/supabase";
import { t, num } from "../i18n";
import { Trophy } from "lucide-react";
import { Empty } from "../components/UI";
type Row = {
  user_id: string;
  hero_name: string;
  score: number;
  days_survived: number;
};
export default function Leaderboard() {
  const [rows, setRows] = useState<Row[]>([]),
    [loading, setLoading] = useState(true),
    [error, setError] = useState(false);
  useEffect(() => {
    let live = true;
    supabase
      .from("leaderboard")
      .select("user_id,hero_name,score,days_survived")
      .order("score", { ascending: false })
      .limit(20)
      .then(({ data, error }) => {
        if (live) {
          setRows(data || []);
          setError(!!error);
          setLoading(false);
        }
      });
    return () => {
      live = false;
    };
  }, []);
  return (
    <div className="page">
      <div className="page-title">
        <span className="eyebrow">{t.rank}</span>
        <h1>{t.leaderboard}</h1>
        <p>{t.leaderboardHint}</p>
      </div>
      <section className="table-card">
        {loading ? (
          <Empty>{t.loading}</Empty>
        ) : error ? (
          <Empty>{t.errorLeaderboard}</Empty>
        ) : !rows.length ? (
          <Empty>{t.emptyLeaderboard}</Empty>
        ) : (
          <table>
            <thead>
              <tr>
                <th>{t.rank}</th>
                <th>{t.name}</th>
                <th>{t.score}</th>
                <th>{t.daysSurvived}</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r, i) => (
                <tr key={r.user_id}>
                  <td>
                    <Trophy size={15} />
                    {num(i + 1)}
                  </td>
                  <td>{r.hero_name}</td>
                  <td>{num(r.score)}</td>
                  <td>{num(r.days_survived)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  );
}
