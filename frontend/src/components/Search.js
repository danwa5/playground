import { useState } from 'react';
import { DatePicker } from '@mui/x-date-pickers';
import {
    Container,
    Button,
    FormControl,
    Select,
    MenuItem,
} from '@mui/material';
import { format } from 'date-fns';
import axios from 'axios';
import { allTeams } from '../allTeams.const';

const firstGameDate = new Date(2022, 9, 18); // Oct 18, 2022
const lastGameDate = new Date(2023, 3, 9); // Apr 9, 2023

function Search({ onQuery }) {
    const [selectedTeam, setSelectedTeam] = useState('GS');
    const [selectedDate, setSelectedDate] = useState(lastGameDate);

    const handleSearch = (e) => {
        e.preventDefault();
        const formattedDate = format(selectedDate, 'yyyy-MM-dd');

        axios
            .get(
                `${process.env.REACT_APP_API_URL}${selectedTeam}?date=${formattedDate}`
            )
            .then((res) => {
                const results = res.data;
                onQuery(results);
            });
    };

    return (
        <Container maxWidth='md'>
            <FormControl
                sx={{ m: 1, maxWidth: 230, minWidth: 230 }}
                size='small'
            >
                <Select
                    name='team'
                    defaultValue='GS'
                    onChange={(e) => {
                        setSelectedTeam(e.target.value);
                    }}
                >
                    {Object.entries(allTeams).map(([teamKey, teamName]) => (
                        <MenuItem key={teamKey} value={teamKey}>
                            {teamName}
                        </MenuItem>
                    ))}
                </Select>
            </FormControl>

            <FormControl sx={{ m: 1, minWidth: 120 }} size='small'>
                <DatePicker
                    defaultValue={lastGameDate}
                    minDate={firstGameDate}
                    maxDate={lastGameDate}
                    onChange={(newValue) => setSelectedDate(newValue)}
                    slotProps={{ textField: { size: 'small' } }}
                />
            </FormControl>

            <FormControl sx={{ m: 1, minWidth: 100 }} size='small'>
                <Button variant='contained' size='large' onClick={handleSearch}>
                    Search
                </Button>
            </FormControl>
        </Container>
    );
}

export default Search;
