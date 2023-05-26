import React, { useState } from 'react';
import Search from './components/Search.js';
import Results from './components/Results.js';
import { LocalizationProvider } from '@mui/x-date-pickers';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
// import './App.css';

function App() {
    const [results, setResults] = useState([]);

    return (
        <LocalizationProvider dateAdapter={AdapterDateFns}>
            <div className='App'>
                <header className='App-header'>
                    <Search onQuery={setResults} />
                    <Results players={results} />
                </header>
            </div>
        </LocalizationProvider>
    );
}

export default App;
