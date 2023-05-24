import React from 'react';
import axios from 'axios';

function Search({ onQuery }) {
    const allTeams = {
        ATL: 'Atlanta Hawks',
        BKN: 'Brooklyn Nets',
        BOS: 'Boston Celtics',
        CHA: 'Charlotte Hornets',
        CHI: 'Chicago Bulls',
        CLE: 'Cleveland Cavaliers',
        DAL: 'Dallas Mavericks',
        DEN: 'Denver Nugggets',
        DET: 'Detroit Pistons',
        GS: 'Golden State Warriors',
        HOU: 'Houston Rockets',
        IND: 'Indiana Pacers',
        LAC: 'Los Angeles Clippers',
        LAL: 'Los Angeles Lakers',
        MEM: 'Memphis Grizzlies',
        MIA: 'Miami Heat',
        MIL: 'Milwaukee Bucks',
        NO: 'New Orleans Pelicans',
        NY: 'New York Knicks',
        OKC: 'Oklahoma City Thunder',
        ORL: 'Orlando Magic',
        PHI: 'Philadelphia 76ers',
        PHO: 'Phoenix Suns',
        POR: 'Portland Trailblazers',
        SA: 'San Antonio Spurs',
        SAC: 'Sacramento Kings',
        TOR: 'Toronto Raptors',
        UTA: 'Utah Jazz',
        WAS: 'Washington Wizards',
    };

    function buildTeamOptions() {
        return Object.entries(allTeams).map(([teamKey, teamName]) => (
            <option value={teamKey}>{teamName}</option>
        ));
    }

    function handleChange(e) {
        let teamKey = e.target.value;

        axios
            .get(`${process.env.REACT_APP_API_URL}${teamKey}?date=2023-04-20`)
            .then((res) => {
                console.log(res);
                const results = res.data.stats;
                onQuery(results);
            });
    }

    return (
        <select name='team' onChange={handleChange}>
            {buildTeamOptions()}
        </select>
    );
}

export default Search;
