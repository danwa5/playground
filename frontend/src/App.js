import React, { useState } from 'react';
import Search from './components/Search.js';
import Results from './components/Results.js';
import './App.css';

function App() {
    const [results, setResults] = useState([]);

    return (
        <div className='App'>
            <header className='App-header'>
                <Search onQuery={setResults} />
                <Results players={results} />
            </header>
        </div>
    );
}

export default App;
