import React, { useState } from 'react';
import Search from './components/Search.js';
import Results from './components/Results.js';
import { Container } from '@mui/material';
import { LocalizationProvider } from '@mui/x-date-pickers';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import '@fontsource/roboto/300.css';
import '@fontsource/roboto/400.css';
import '@fontsource/roboto/500.css';
import '@fontsource/roboto/700.css';

function App() {
    const [results, setResults] = useState();

    return (
        <LocalizationProvider dateAdapter={AdapterDateFns}>
            <div className='App'>
                <Container maxWidth='xl'>
                    <Search onQuery={setResults} />
                    {results && <Results data={results} />}
                </Container>
            </div>
        </LocalizationProvider>
    );
}

export default App;
