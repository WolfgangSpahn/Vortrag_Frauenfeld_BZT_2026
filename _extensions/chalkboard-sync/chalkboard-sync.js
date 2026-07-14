/*****************************************************************
** Author: Wolfgang Spahn, wolfgang.spahn@phbern.ch
**
** A plugin for adding a chalkboard update button to the chalkboard
** toolbar, preparing to synchronize chalkboard content across multiple
** clients via server-sent events (SSE).
**
**
** Version: 0.1
**
** License: MIT license (see file LICENSE)
**
******************************************************************/

window.RevealChalkboardSync = window.RevealChalkboardSync || {
  id: 'RevealChalkboardSync',
  init: function(deck) {
      initChalkboardSync(deck);
  }
};

const initChalkboardSync = function(Reveal){

  function createButton(container, idSuffix) {
    const btnId = 'chalkboard-update-btn-' + idSuffix;
    
    // Check if button already exists in this container
    if (container.querySelector('#' + btnId)) return;

    const btn = document.createElement('button');
    btn.id = btnId;
    btn.className = 'chalkboard-update-btn';
    btn.textContent = 'Update';
    
    // Better styling to make it stand out - positioned absolutely
    btn.style.position = 'absolute';
    btn.style.top = '10px';
    btn.style.right = '10px';
    btn.style.padding = '0.5em 1em';
    btn.style.borderRadius = '4px';
    btn.style.border = '2px solid #333';
    btn.style.background = '#4CAF50';
    btn.style.color = 'white';
    btn.style.fontWeight = 'bold';
    btn.style.fontSize = '14px';
    btn.style.cursor = 'pointer';
    btn.style.textAlign = 'center';
    btn.style.boxShadow = '0 2px 4px rgba(0,0,0,0.2)';
    btn.style.transition = 'all 0.3s ease';
    btn.style.zIndex = '9999';
    btn.style.pointerEvents = 'auto'; // Enable clicking even if parent has pointer-events: none
    
    // Hover effect
    btn.addEventListener('mouseenter', () => {
      btn.style.background = '#45a049';
      btn.style.transform = 'scale(1.05)';
    });
    
    btn.addEventListener('mouseleave', () => {
      btn.style.background = '#4CAF50';
      btn.style.transform = 'scale(1)';
    });

    btn.addEventListener('click', async () => {
      const data = RevealChalkboard.getData();
      await fetch('/update-chalkboard', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type: 'chalkboard-update', data })
      });
    });

    container.appendChild(btn);
  }

  function addUpdateButton() {
    // Find the chalkboard overlay containers
    const notesCanvas = document.getElementById('notescanvas');
    const chalkboard = document.getElementById('chalkboard');
    
    // Add button to notes canvas (for drawing on slides)
    if (notesCanvas) {
      createButton(notesCanvas, 'notes');
    }
    
    // Add button to chalkboard (for the blackboard/whiteboard)
    if (chalkboard) {
      createButton(chalkboard, 'board');
    }
  }

  function startSSEListener() {
    const evtSource = new EventSource('/events');
    evtSource.onmessage = (event) => {
      const msg = JSON.parse(event.data);
      if (msg.type === 'chalkboard-update') {
        if (!RevealChalkboard.isOpen()) RevealChalkboard.toggleChalkboard();
        RevealChalkboard.setData(msg.data);
      }
    };
  }

  window.addEventListener('ready', function(event) {
    // Wait for chalkboard plugin to be available
    const checkReady = setInterval(() => {
      if (window.RevealChalkboard) {
        clearInterval(checkReady);
        
        // Try to add button immediately if chalkboard is already open
        addUpdateButton();
        
        // Also add button whenever chalkboard is toggled
        const orig = RevealChalkboard.toggleChalkboard;
        RevealChalkboard.toggleChalkboard = function() {
          orig.apply(this, arguments);
          setTimeout(addUpdateButton, 300);
        };
        
        startSSEListener();
      }
    }, 500);
  });

};
