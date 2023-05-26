import React from 'react';

function Results({ players }) {
    function fg3Perc(fg3m, fg3a) {
        return ((fg3m / fg3a) * 100).toFixed(1) + '%';
    }

    function fg3PerGame(fg3m, games) {
        return (fg3m / games).toFixed(1);
    }

    return (
        <table>
            <tbody>
                <tr>
                    <th>Player</th>
                    <th>Games</th>
                    <th>3PT Made</th>
                    <th>3PT Attempts</th>
                    <th>3PT%</th>
                    <th>3PT Per Game</th>
                </tr>
                {players.map((player) => (
                    <tr key={player.player_id}>
                        <td>{player.player_name}</td>
                        <td>{player.games_played}</td>
                        <td>{player.season_3fgm}</td>
                        <td>{player.season_3fga}</td>
                        <td>
                            {fg3Perc(player.season_3fgm, player.season_3fga)}
                        </td>
                        <td>
                            {fg3PerGame(
                                player.season_3fgm,
                                player.games_played
                            )}
                        </td>
                    </tr>
                ))}
            </tbody>
        </table>
    );
}

export default Results;
