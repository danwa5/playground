import React from 'react';
import {
    Container,
    Paper,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
} from '@mui/material';

function Results({ players }) {
    function fg3Perc(fg3m, fg3a) {
        return ((fg3m / fg3a) * 100).toFixed(1);
    }

    function fg3PerGame(fg3m, games) {
        return (fg3m / games).toFixed(1);
    }

    return (
        <Container maxWidth='md'>
            <TableContainer component={Paper}>
                <Table
                    sx={{ minWidth: 800 }}
                    size='small'
                    aria-label='table of player data'
                >
                    <TableHead>
                        <TableRow>
                            <TableCell>Player</TableCell>
                            <TableCell align='right'>Games</TableCell>
                            <TableCell align='right'>3PT Made</TableCell>
                            <TableCell align='right'>3PT Attempts</TableCell>
                            <TableCell align='right'>3PT%</TableCell>
                            <TableCell align='right'>3PT Per Game</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {players.map((player) => (
                            <TableRow
                                key={player.player_id}
                                sx={{
                                    '&:last-child td, &:last-child th': {
                                        border: 0,
                                    },
                                }}
                            >
                                <TableCell component='th' scope='row'>
                                    {player.player_name}
                                </TableCell>
                                <TableCell align='right'>
                                    {player.games_played}
                                </TableCell>
                                <TableCell align='right'>
                                    {player.season_3fgm}
                                </TableCell>
                                <TableCell align='right'>
                                    {player.season_3fga}
                                </TableCell>
                                <TableCell align='right'>
                                    {fg3Perc(
                                        player.season_3fgm,
                                        player.season_3fga
                                    )}
                                </TableCell>
                                <TableCell align='right'>
                                    {fg3PerGame(
                                        player.season_3fgm,
                                        player.games_played
                                    )}
                                </TableCell>
                            </TableRow>
                        ))}
                    </TableBody>
                </Table>
            </TableContainer>
        </Container>
    );
}

export default Results;
