/**
 * District Car Admin Web — Core Application & UI Controller
 * Includes Driver Commissions & Settlements, KYC Verification, and Ride Accounting
 */

document.addEventListener('DOMContentLoaded', () => {
  // 1. Initialize UI Elements & Event Listeners
  setupPinLock();
  setupNavigation();
  setupSearch();
  setupClock();

  // 2. Start Live Data Stream
  initRealtimeListeners((changedCollection) => {
    console.log(`🔄 [AdminApp] Render triggered by: ${changedCollection}`);
    renderAllViews();
  });

  // Render initial frame
  renderAllViews();
});

// Current active view
let currentView = 'dashboard';
let revenueChart = null;

/**
 * Universal Driver Name Getter
 * Ensures driver name is ALWAYS properly resolved from any Firestore schema
 */
function getDriverName(d) {
  if (!d) return 'Driver Partner';
  if (typeof d === 'string') return d;

  const candidate = d.name || d.fullName || d.driverName || d.displayName || 
                    d.personalDetails?.fullName || d.personalDetails?.name ||
                    d.profile?.name || d.profile?.fullName;

  if (candidate && candidate.trim().length > 0 && candidate.trim().toLowerCase() !== 'unnamed driver') {
    return candidate.trim();
  }

  // If phone exists
  const phone = d.phoneNumber || d.driverPhone || d.phone;
  if (phone && phone.trim().length > 0) {
    const cleanPhone = phone.trim();
    return `Driver (${cleanPhone.length > 5 ? cleanPhone.slice(-5) : cleanPhone})`;
  }

  // If email exists
  if (d.email && d.email.trim().length > 0) {
    const prefix = d.email.split('@')[0];
    return prefix.charAt(0).toUpperCase() + prefix.slice(1);
  }

  if (d.id) {
    return `Partner #${d.id.substring(0, 6).toUpperCase()}`;
  }

  return 'Driver Partner';
}

/**
 * 1. Navigation Controller
 */
function setupNavigation() {
  const navItems = document.querySelectorAll('.nav-item');
  navItems.forEach((item) => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      const target = item.getAttribute('data-view');
      switchView(target);

      // Close mobile sidebar if open
      const sb = document.querySelector('.sidebar');
      if (sb) sb.classList.remove('open');
    });
  });

  // Mobile toggle
  const mobileToggle = document.getElementById('mobileToggle');
  if (mobileToggle) {
    mobileToggle.addEventListener('click', () => {
      const sb = document.querySelector('.sidebar');
      if (sb) sb.classList.toggle('open');
    });
  }
}

function switchView(viewName) {
  currentView = viewName;

  // Update nav active state
  document.querySelectorAll('.nav-item').forEach((el) => {
    if (el.getAttribute('data-view') === viewName) {
      el.classList.add('active');
    } else {
      el.classList.remove('active');
    }
  });

  // Update view visibility
  document.querySelectorAll('.view-section').forEach((sec) => {
    if (sec.id === `view-${viewName}`) {
      sec.classList.add('active');
    } else {
      sec.classList.remove('active');
    }
  });

  // Re-render target view
  renderCurrentView();
}

/**
 * 2. Clock & Topbar
 */
function setupClock() {
  const clockEl = document.getElementById('liveClock');
  if (!clockEl) return;

  function update() {
    const now = new Date();
    clockEl.innerText = now.toLocaleDateString('en-IN', {
      weekday: 'short',
      day: 'numeric',
      month: 'short',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
  }
  update();
  setInterval(update, 1000);
}

/**
 * 3. Master Render Orchestrator
 */
function renderAllViews() {
  renderMetrics();
  renderRevenueChart();
  renderDriversTable();
  renderUsersTable();
  renderBookingsTable();
  renderCommissionView();
  renderPayoutsTable();
  renderRemoteConfigView();
  updateGuestPopupUI();
  updateNavBadges();
}

function renderCurrentView() {
  if (currentView === 'dashboard') {
    renderMetrics();
    renderRevenueChart();
  } else if (currentView === 'drivers') {
    renderDriversTable();
  } else if (currentView === 'users') {
    renderUsersTable();
  } else if (currentView === 'bookings') {
    renderBookingsTable();
  } else if (currentView === 'commissions') {
    renderCommissionView();
  } else if (currentView === 'payouts') {
    renderPayoutsTable();
  } else if (currentView === 'updates') {
    renderRemoteConfigView();
  } else if (currentView === 'pricing') {
    renderPricingView();
  }
}

function updateNavBadges() {
  // Pending Drivers KYC Badge
  const pendingDrivers = AdminStore.drivers.filter(d => d.verificationStatus === 'pending').length;
  const badgeDrivers = document.getElementById('badgePendingDrivers');
  if (badgeDrivers) {
    badgeDrivers.innerText = pendingDrivers > 0 ? pendingDrivers : '';
    badgeDrivers.style.display = pendingDrivers > 0 ? 'inline-block' : 'none';
  }

  // Pending Payouts Badge
  const pendingPayouts = AdminStore.payouts.filter(p => p.status === 'pending').length;
  const badgePayouts = document.getElementById('badgePendingPayouts');
  if (badgePayouts) {
    badgePayouts.innerText = pendingPayouts > 0 ? pendingPayouts : '';
    badgePayouts.style.display = pendingPayouts > 0 ? 'inline-block' : 'none';
  }

  // Outstanding Commission / 3-Trip Locked Badge
  const lockedDrivers = AdminStore.drivers.filter(d => (parseInt(d.unpaidTripsCount, 10) || 0) >= 3).length;
  const badgeComm = document.getElementById('badgePendingCommissions');
  if (badgeComm) {
    badgeComm.innerText = lockedDrivers > 0 ? `${lockedDrivers} Locked` : '';
    badgeComm.style.display = lockedDrivers > 0 ? 'inline-block' : 'none';
  }
}

/**
 * Helper to extract or calculate total distance in KM for a booking
 */
function getBookingDistanceKm(b) {
  if (!b) return null;
  const candidates = [b.estimatedDistanceKm, b.distanceKm, b.distance, b.approxDistanceKm, b.totalKm];
  for (const c of candidates) {
    if (c !== undefined && c !== null && !isNaN(c) && Number(c) > 0) {
      return Math.round(Number(c) * 10) / 10;
    }
  }
  // Fallback calculate from coordinates if present
  const pLat = b.pickup?.latitude;
  const pLng = b.pickup?.longitude;
  const dLat = b.destination?.latitude;
  const dLng = b.destination?.longitude;
  if (pLat && pLng && dLat && dLng) {
    const R = 6371;
    const dLatRad = (dLat - pLat) * Math.PI / 180;
    const dLngRad = (dLng - pLng) * Math.PI / 180;
    const a = Math.sin(dLatRad / 2) * Math.sin(dLatRad / 2) +
              Math.cos(pLat * Math.PI / 180) * Math.cos(dLat * Math.PI / 180) *
              Math.sin(dLngRad / 2) * Math.sin(dLngRad / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const aerialKm = R * c;
    const roadKm = Math.round((aerialKm * 1.25) * 10) / 10;
    return roadKm > 0 ? roadKm : null;
  }
  return null;
}

/**
 * 4. Dashboard Metrics Calculation
 */
function renderMetrics() {
  const bookings = AdminStore.bookings;
  const drivers = AdminStore.drivers;
  const users = AdminStore.users;

  // Filter completed bookings
  const completedBookings = bookings.filter(b => b.status === 'completed' || b.status === 'trip_completed');

  // Gross Earnings
  const totalGross = completedBookings.reduce((sum, b) => {
    const fare = parseFloat(b.finalFare || b.estimatedFare || 0);
    return sum + (isNaN(fare) ? 0 : fare);
  }, 0);

  // Platform 10% Commission
  const platformCommission = totalGross * 0.10;

  // Driver 90% Net Share
  const driverNetShare = totalGross * 0.90;

  // Active / Online Drivers
  const onlineDrivers = drivers.filter(d => d.isOnline === true).length;
  const approvedDrivers = drivers.filter(d => d.verificationStatus === 'approved').length;

  // Update DOM Elements
  safeSetText('metricTotalRevenue', `₹${Math.round(totalGross).toLocaleString('en-IN')}`);
  safeSetText('metricCommission', `₹${Math.round(platformCommission).toLocaleString('en-IN')}`);
  safeSetText('metricDriverShare', `₹${Math.round(driverNetShare).toLocaleString('en-IN')}`);
  safeSetText('metricTotalRides', completedBookings.length.toLocaleString('en-IN'));
  const totalKm = completedBookings.reduce((sum, b) => {
    const d = getBookingDistanceKm(b);
    return sum + (d || 0);
  }, 0);
  safeSetText('metricTotalKm', `${Math.round(totalKm).toLocaleString('en-IN')} km`);
  safeSetText('metricActiveDrivers', `${onlineDrivers} / ${approvedDrivers}`);
  safeSetText('metricTotalUsers', users.length.toLocaleString('en-IN'));

  // Live status in sidebar
  const liveIndicatorText = document.getElementById('liveSyncText');
  if (liveIndicatorText) {
    liveIndicatorText.innerText = AdminStore.isLive ? 'Live Firestore Sync' : 'Simulated Data';
  }
}

/**
 * 5. Chart.js Revenue Trend
 */
function renderRevenueChart() {
  const canvas = document.getElementById('revenueChartCanvas');
  if (!canvas || typeof Chart === 'undefined') return;

  const ctx = canvas.getContext('2d');
  if (!ctx) return;

  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const revenueData = [12400, 15800, 18900, 14200, 22400, 28900, 24500];
  const commissionData = revenueData.map(v => Math.round(v * 0.10));

  if (revenueChart) {
    revenueChart.destroy();
  }

  revenueChart = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: days,
      datasets: [
        {
          label: 'Gross Bookings (₹)',
          data: revenueData,
          backgroundColor: '#059669',
          borderRadius: 6,
          barPercentage: 0.6
        },
        {
          label: 'Platform Commission 10% (₹)',
          data: commissionData,
          backgroundColor: '#0F172A',
          borderRadius: 6,
          barPercentage: 0.6
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: 'top',
          labels: { font: { family: 'Plus Jakarta Sans', weight: '700' } }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          grid: { color: '#F1F5F9' },
          ticks: {
            callback: (val) => '₹' + val.toLocaleString('en-IN'),
            font: { family: 'Plus Jakarta Sans' }
          }
        },
        x: {
          grid: { display: false },
          font: { family: 'Plus Jakarta Sans', weight: '600' }
        }
      }
    }
  });
}

/**
 * 6. Drivers Table Controller
 */
function renderDriversTable() {
  const tbody = document.getElementById('driversTableBody');
  if (!tbody) return;

  const filterStatus = document.getElementById('driverStatusFilter')?.value || 'all';
  const searchTerm = (document.getElementById('driverSearchInput')?.value || '').toLowerCase();

  let list = AdminStore.drivers.filter((d) => {
    // Filter status
    if (filterStatus === 'online' && !d.isOnline) return false;
    if (filterStatus === 'pending' && d.verificationStatus !== 'pending') return false;
    if (filterStatus === 'approved' && d.verificationStatus !== 'approved') return false;
    if (filterStatus === 'unpaid_lock' && (parseInt(d.unpaidTripsCount, 10) || 0) < 3) return false;

    // Search term
    if (searchTerm) {
      const name = getDriverName(d).toLowerCase();
      const phone = (d.phoneNumber || '').toLowerCase();
      const plate = (d.vehiclePlateNumber || '').toLowerCase();
      if (!name.includes(searchTerm) && !phone.includes(searchTerm) && !plate.includes(searchTerm)) {
        return false;
      }
    }
    return true;
  });

  if (list.length === 0) {
    tbody.innerHTML = `<tr><td colspan="10" style="text-align:center; padding:36px; color:#64748B;">
      <i class="fa-solid fa-car-tunnel" style="font-size:28px; display:block; margin-bottom:10px; color:#CBD5E1;"></i>
      No drivers found matching your filter criteria.
    </td></tr>`;
    return;
  }

  let html = '';
  list.forEach((d) => {
    const driverName = getDriverName(d);
    const isOnline = d.isOnline === true;
    const isBusy = d.driverStatus === 'busy';
    const statusChip = isBusy 
      ? '<span class="badge badge-warning"><i class="fa-solid fa-circle-dot"></i> Busy (On Ride)</span>'
      : (isOnline ? '<span class="badge badge-success"><i class="fa-solid fa-signal"></i> Online</span>' : '<span class="badge badge-neutral"><i class="fa-solid fa-moon"></i> Offline</span>');

    const kycChip = d.verificationStatus === 'approved'
      ? '<span class="badge badge-success"><i class="fa-solid fa-check"></i> Approved</span>'
      : (d.verificationStatus === 'rejected' ? '<span class="badge badge-danger"><i class="fa-solid fa-xmark"></i> Rejected</span>' : '<span class="badge badge-warning"><i class="fa-solid fa-clock"></i> Pending KYC</span>');

    const unpaidCount = parseInt(d.unpaidTripsCount || 0, 10);
    const unpaidBadge = unpaidCount >= 3
      ? `<span class="badge badge-danger" title="Locked by 3-Trip Rule"><i class="fa-solid fa-lock"></i> ${unpaidCount} / 3 (Locked)</span>`
      : `<span class="badge badge-neutral">${unpaidCount} / 3</span>`;

    const wallet = parseFloat(d.walletBalance || 0);
    const comm = parseFloat(d.pendingCommission || 0);

    html += `
      <tr>
        <td>
          <div style="display:flex; align-items:center; gap:10px;">
            <div style="width:38px; height:38px; border-radius:50%; background:#064E3B; color:#FFF; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:14px; flex-shrink:0;">
              ${(driverName[0] || 'D').toUpperCase()}
            </div>
            <div>
              <strong style="display:block; font-size:14px; color:#0F172A;">${driverName}</strong>
              <span style="font-size:12px; color:#64748B;">ID: ${d.id.substring(0, 10)}</span>
            </div>
          </div>
        </td>
        <td>
          <a href="tel:${d.phoneNumber}" style="color:#059669; font-weight:700; text-decoration:none; display:inline-flex; align-items:center; gap:5px;">
            <i class="fa-solid fa-phone"></i> ${d.phoneNumber || 'N/A'}
          </a>
        </td>
        <td>
          <span class="badge-category">${(d.vehicleCategoryId || 'CAB').toUpperCase()}</span>
          <span style="display:block; font-size:12px; color:#475569; margin-top:2px;">${d.vehicleModel || ''}</span>
          <strong style="font-size:12px; color:#0F172A;">${d.vehiclePlateNumber || 'No Plate'}</strong>
        </td>
        <td>${statusChip}</td>
        <td>${kycChip}</td>
        <td><strong style="font-size:14px; color:#064E3B;">${d.totalTrips || 0}</strong></td>
        <td><strong style="color:#059669; font-size:14px;">₹${wallet.toLocaleString('en-IN')}</strong></td>
        <td><strong style="color:#B91C1C; font-size:14px;">₹${comm.toLocaleString('en-IN')}</strong></td>
        <td>${unpaidBadge}</td>
        <td>
          <div class="action-btns">
            <button class="btn btn-secondary btn-sm" onclick="openDriverModal('${d.id}')" title="View Full Profile & KYC">
              <i class="fa-solid fa-eye"></i>
            </button>
            ${d.verificationStatus === 'pending' ? `
              <button class="btn btn-success btn-sm" onclick="approveDriverKYC('${d.id}')" title="Approve Driver">
                <i class="fa-solid fa-check"></i>
              </button>
              <button class="btn btn-danger btn-sm" onclick="rejectDriverKYC('${d.id}')" title="Reject Driver">
                <i class="fa-solid fa-xmark"></i>
              </button>
            ` : ''}
            <button class="btn btn-primary btn-sm" onclick="openSettlePaymentModal('${d.id}')" title="Settle 10% Platform Fee">
              <i class="fa-solid fa-hand-holding-dollar"></i> Settle
            </button>
            <button class="btn btn-danger btn-sm" onclick="deleteDriver('${d.id}')" title="Permanently Delete Driver">
              <i class="fa-solid fa-trash-can"></i>
            </button>
          </div>
        </td>
      </tr>
    `;
  });

  tbody.innerHTML = html;
}

/**
 * 7. Users / Customers Table Controller
 */
function renderUsersTable() {
  const tbody = document.getElementById('usersTableBody');
  if (!tbody) return;

  const searchTerm = (document.getElementById('userSearchInput')?.value || '').toLowerCase();

  let list = AdminStore.users.filter((u) => {
    if (searchTerm) {
      const name = (u.displayName || u.name || '').toLowerCase();
      const phone = (u.phoneNumber || u.phone || '').toLowerCase();
      const email = (u.email || '').toLowerCase();
      if (!name.includes(searchTerm) && !phone.includes(searchTerm) && !email.includes(searchTerm)) {
        return false;
      }
    }
    return true;
  });

  if (list.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" style="text-align:center; padding:36px; color:#64748B;">No users found.</td></tr>`;
    return;
  }

  let html = '';
  list.forEach((u) => {
    const isBlocked = u.isBlocked === true;
    const statusChip = isBlocked
      ? '<span class="badge badge-danger">Blocked</span>'
      : '<span class="badge badge-success">Active</span>';

    const userName = u.displayName || u.name || 'District Customer';

    html += `
      <tr>
        <td>
          <div style="display:flex; align-items:center; gap:10px;">
            <div style="width:34px; height:34px; border-radius:50%; background:#1E293B; color:#FFF; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12.5px;">
              ${(userName[0] || 'U').toUpperCase()}
            </div>
            <div>
              <strong style="display:block; color:#0F172A;">${userName}</strong>
              <span style="font-size:12px; color:#64748B;">${u.email || 'No Email'}</span>
            </div>
          </div>
        </td>
        <td>
          <a href="tel:${u.phoneNumber || u.phone}" style="color:#059669; font-weight:700; text-decoration:none;">
            <i class="fa-solid fa-phone"></i> ${u.phoneNumber || u.phone || 'N/A'}
          </a>
        </td>
        <td>${statusChip}</td>
        <td><strong>${u.totalBookings || 1}</strong></td>
        <td><strong style="color:#059669;">₹${(u.totalSpent || 450).toLocaleString('en-IN')}</strong></td>
        <td>${u.createdAt ? new Date(u.createdAt.seconds ? u.createdAt.seconds * 1000 : u.createdAt).toLocaleDateString('en-IN') : 'N/A'}</td>
        <td>
          <div class="action-btns">
            <button class="btn ${isBlocked ? 'btn-success' : 'btn-danger'} btn-sm" onclick="toggleUserBlock('${u.id}', ${isBlocked})">
              <i class="fa-solid ${isBlocked ? 'fa-unlock' : 'fa-ban'}"></i> ${isBlocked ? 'Unblock' : 'Block'}
            </button>
            <button class="btn btn-danger btn-sm" onclick="deleteUser('${u.id}')" title="Permanently Delete Customer">
              <i class="fa-solid fa-trash-can"></i>
            </button>
          </div>
        </td>
      </tr>
    `;
  });

  tbody.innerHTML = html;
}

/**
 * 8. Bookings & Commission Table Controller
 */
function renderBookingsTable() {
  const tbody = document.getElementById('bookingsTableBody');
  if (!tbody) return;

  const filterStatus = document.getElementById('bookingStatusFilter')?.value || 'all';
  const searchTerm = (document.getElementById('bookingSearchInput')?.value || '').toLowerCase();

  let list = AdminStore.bookings.filter((b) => {
    // Filter status
    if (filterStatus === 'completed' && !(b.status === 'completed' || b.status === 'trip_completed')) return false;
    if (filterStatus === 'in_progress' && !(b.status === 'driver_assigned' || b.status === 'driver_arrived' || b.status === 'trip_started')) return false;
    if (filterStatus === 'searching' && b.status !== 'searching_driver') return false;
    if (filterStatus === 'cancelled' && !b.status.includes('cancelled')) return false;

    // Search term
    if (searchTerm) {
      const rId = (b.readableId || b.id || '').toLowerCase();
      const cName = (b.customerName || '').toLowerCase();
      const cPhone = (b.customerPhone || '').toLowerCase();
      const dName = (b.driverName || '').toLowerCase();
      if (!rId.includes(searchTerm) && !cName.includes(searchTerm) && !cPhone.includes(searchTerm) && !dName.includes(searchTerm)) {
        return false;
      }
    }
    return true;
  });

  if (list.length === 0) {
    tbody.innerHTML = `<tr><td colspan="10" style="text-align:center; padding:36px; color:#64748B;">No bookings found matching filter.</td></tr>`;
    return;
  }

  let html = '';
  list.forEach((b) => {
    const grossFare = parseFloat(b.finalFare || b.estimatedFare || 0);
    const comm10 = grossFare * 0.10;
    const driver90 = grossFare * 0.90;

    let statusChip = '<span class="badge badge-neutral">' + b.status + '</span>';
    if (b.status === 'completed' || b.status === 'trip_completed') {
      statusChip = '<span class="badge badge-success"><i class="fa-solid fa-check"></i> Completed</span>';
    } else if (b.status === 'trip_started') {
      statusChip = '<span class="badge badge-warning"><i class="fa-solid fa-car-side"></i> In Transit</span>';
    } else if (b.status === 'driver_assigned' || b.status === 'driver_arrived') {
      statusChip = '<span class="badge badge-info"><i class="fa-solid fa-user-check"></i> Assigned</span>';
    } else if (b.status === 'searching_driver') {
      statusChip = '<span class="badge badge-warning"><i class="fa-solid fa-radar"></i> Searching</span>';
    } else if (b.status.includes('cancelled')) {
      statusChip = '<span class="badge badge-danger"><i class="fa-solid fa-ban"></i> Cancelled</span>';
    }

    const pickupStr = b.pickup?.address || 'Pickup Point';
    const destStr = b.destination?.address || 'Destination';
    const dName = b.driverName ? b.driverName : (b.driverId ? `Driver #${b.driverId.substring(0, 6)}` : null);

    const distKm = getBookingDistanceKm(b);

    // Formatted Timing
    const bookingTimeStr = formatTimestamp(b.createdAt) || 'Recent';
    const acceptTimeStr = formatTimestamp(b.driverAcceptedAt || b.acceptedAt);
    const timeDiffMins = getTimeDiffMinutes(b.createdAt, b.driverAcceptedAt || b.acceptedAt);

    let driverCellHtml = '';
    const hasAssignedDriver = b.driverId && (b.status === 'driver_assigned' || b.status === 'driver_arrived' || b.status === 'trip_started' || b.status === 'completed' || b.status === 'trip_completed');

    if (hasAssignedDriver) {
      driverCellHtml = `
        <div>
          <div style="display:flex; align-items:center; gap:6px;">
            <i class="fa-solid fa-circle-check" style="color:#059669; font-size:13px;"></i>
            <strong style="color:#0F172A; font-size:13.5px;">${dName}</strong>
          </div>
          <a href="tel:${b.driverPhone}" style="color:#64748B; font-size:12px; text-decoration:none; display:inline-flex; align-items:center; gap:4px; margin-top:2px;">
            <i class="fa-solid fa-phone" style="color:#059669;"></i> ${b.driverPhone || 'N/A'}
          </a>
          ${acceptTimeStr ? `
            <div style="font-size:11.5px; color:#059669; font-weight:700; margin-top:3px;">
              <i class="fa-solid fa-clock-check"></i> Accepted: ${acceptTimeStr} ${timeDiffMins !== null ? `(+${timeDiffMins}m)` : ''}
            </div>
          ` : `
            <div style="font-size:11px; color:#64748B; margin-top:3px;">
              <i class="fa-solid fa-check"></i> Driver Assigned
            </div>
          `}
          ${(b.status === 'driver_assigned' || b.status === 'driver_arrived' || b.status === 'trip_started') ? `
            <div style="margin-top:6px;">
              <button class="btn btn-danger btn-sm" onclick="handleCancelBooking('${b.id}')" title="Cancel this active ride" style="padding:3px 8px; font-size:11px; background:#FEF2F2; color:#DC2626; border:1px solid #FECACA;">
                <i class="fa-solid fa-ban"></i> Cancel Ride
              </button>
            </div>
          ` : ''}
        </div>
      `;
    } else if (b.status && b.status.includes('cancelled')) {
      driverCellHtml = `
        <div>
          <span class="badge badge-danger"><i class="fa-solid fa-ban"></i> Cancelled</span>
          <span style="display:block; font-size:11px; color:#94A3B8; margin-top:3px;">No Driver Assigned</span>
        </div>
      `;
    } else {
      // NOT ACCEPTED YET -> Dropdown with all available drivers
      const driverOptions = getAvailableDriverOptions(b.vehicleCategoryId);
      driverCellHtml = `
        <div style="min-width:220px;">
          <div style="margin-bottom:6px;">
            <span class="badge badge-warning" style="font-size:11px;">
              <i class="fa-solid fa-hourglass-half"></i> Not Accepted Yet
            </span>
          </div>
          <div style="display:flex; gap:6px; align-items:center; flex-wrap:wrap;">
            <select id="assignSelect_${b.id}" class="filter-select" style="font-size:12px; padding:5px 6px; width:140px; background:#FFFFFF; border:1px solid #CBD5E1;">
              <option value="">-- Assign Driver --</option>
              ${driverOptions}
            </select>
            <button class="btn btn-primary btn-sm" onclick="handleQuickAssign('${b.id}')" title="Assign Selected Driver" style="padding:6px 9px;">
              <i class="fa-solid fa-user-check"></i> Assign
            </button>
            <button class="btn btn-danger btn-sm" onclick="handleCancelBooking('${b.id}')" title="Cancel this Booking" style="padding:6px 9px; background:#FEF2F2; color:#DC2626; border:1px solid #FECACA;">
              <i class="fa-solid fa-ban"></i> Cancel
            </button>
          </div>
        </div>
      `;
    }

    html += `
      <tr>
        <td>
          <strong style="color:#059669; font-size:14px;">${b.readableId || b.id.substring(0, 8)}</strong>
          <span style="display:block; font-size:12px; color:#475569; font-weight:700; margin-top:2px;">
            <i class="fa-regular fa-clock" style="color:#059669;"></i> ${bookingTimeStr}
          </span>
          ${b.rideOtp ? `<span style="display:block; font-size:11px; color:#64748B; font-weight:700; margin-top:2px;">OTP: <span style="background:#FEF08A; padding:1px 5px; border-radius:3px; color:#064E3B;">${b.rideOtp}</span></span>` : ''}
        </td>
        <td>
          <strong style="display:block; color:#0F172A;">${b.customerName || 'Customer'}</strong>
          <a href="tel:${b.customerPhone}" style="color:#64748B; font-size:12px; text-decoration:none;">
            <i class="fa-solid fa-phone" style="color:#059669;"></i> ${b.customerPhone || 'N/A'}
          </a>
        </td>
        <td>
          ${driverCellHtml}
        </td>
        <td>
          <span class="badge-category">${(b.vehicleCategoryId || 'CAB').toUpperCase()}</span>
          ${b.isRoundTrip ? '<span class="badge badge-info" style="margin-left:4px;">Round Trip</span>' : ''}
        </td>
        <td>
          <span style="display:inline-flex; align-items:center; gap:5px; font-size:13px; font-weight:800; color:#1D4ED8; background:#EFF6FF; border:1px solid #BFDBFE; padding:3px 9px; border-radius:20px; white-space:nowrap;">
            <i class="fa-solid fa-road"></i> ${distKm !== null ? `${distKm} km` : 'N/A'}
          </span>
          ${b.isRoundTrip ? '<span style="display:block; font-size:10.5px; color:#7C3AED; font-weight:700; margin-top:3px;">Round Trip</span>' : ''}
        </td>
        <td style="max-width:240px;">
          <div style="font-size:12.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">
            <i class="fa-solid fa-location-dot" style="color:#059669; width:14px;"></i> ${pickupStr}
          </div>
          <div style="font-size:12.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; color:#64748B; margin-top:2px;">
            <i class="fa-solid fa-flag-checkered" style="color:#DC2626; width:14px;"></i> ${destStr}
          </div>
          ${distKm !== null ? `
            <div style="margin-top:3px; font-size:11px; color:#2563EB; font-weight:700;">
              <i class="fa-solid fa-route"></i> Total Distance: <strong>${distKm} km</strong>
            </div>
          ` : ''}
        </td>
        <td>${statusChip}</td>
        <td><strong style="font-size:14px; color:#0F172A;">₹${grossFare.toFixed(0)}</strong></td>
        <td><strong style="font-size:14px; color:#B91C1C;">₹${comm10.toFixed(0)}</strong></td>
        <td><strong style="font-size:14px; color:#059669;">₹${driver90.toFixed(0)}</strong></td>
        <td>
          <div class="action-btns">
            <button class="btn btn-secondary btn-sm" onclick="openBookingAuditModal('${b.id}')" title="View Details">
              <i class="fa-solid fa-receipt"></i> Details
            </button>
            ${(!b.status.includes('cancelled') && b.status !== 'completed' && b.status !== 'trip_completed') ? `
              <button class="btn btn-sm" onclick="handleCancelBooking('${b.id}')" title="Cancel Booking" style="background:#FEF2F2; color:#DC2626; border:1px solid #FECACA; padding:5px 8px;">
                <i class="fa-solid fa-ban"></i> Cancel
              </button>
            ` : ''}
            <button class="btn btn-danger btn-sm" onclick="deleteBooking('${b.id}')" title="Permanently Delete Booking">
              <i class="fa-solid fa-trash-can"></i>
            </button>
          </div>
        </td>
      </tr>
    `;
  });

  tbody.innerHTML = html;
}

/**
 * 9. Driver Commission & Settlements Category Controller
 */
function renderCommissionView() {
  const drivers = AdminStore.drivers;
  const bookings = AdminStore.bookings;
  const settlements = AdminStore.settlements;

  // 1. Calculate Summary Cards
  const completedBookings = bookings.filter(b => b.status === 'completed' || b.status === 'trip_completed');
  const totalGross = completedBookings.reduce((sum, b) => {
    const f = parseFloat(b.finalFare || b.estimatedFare || 0);
    return sum + (isNaN(f) ? 0 : f);
  }, 0);

  const totalCommAccrued = totalGross * 0.10;
  const totalCommDue = drivers.reduce((sum, d) => sum + (parseFloat(d.pendingCommission) || 0), 0);
  const totalSettledFromDrivers = drivers.reduce((sum, d) => sum + (parseFloat(d.totalCommissionSettled) || 0), 0);
  const totalSettledFromAudit = settlements.reduce((sum, s) => sum + (parseFloat(s.amountSettled) || 0), 0);
  const totalSettled = Math.max(totalSettledFromDrivers, totalSettledFromAudit);

  const lockedDriversCount = drivers.filter(d => (parseInt(d.unpaidTripsCount, 10) || 0) >= 3).length;

  safeSetText('commTotalAccrued', `₹${Math.round(totalCommAccrued).toLocaleString('en-IN')}`);
  safeSetText('commTotalDue', `₹${Math.round(totalCommDue).toLocaleString('en-IN')}`);
  safeSetText('commTotalSettled', `₹${Math.round(totalSettled).toLocaleString('en-IN')}`);
  safeSetText('commLockedDrivers', `${lockedDriversCount} Drivers Locked`);

  // 2. Render Driver Commission Ledger Table
  const tbodyLedger = document.getElementById('commissionTableBody');
  if (tbodyLedger) {
    const filter = document.getElementById('commStatusFilter')?.value || 'all';
    const search = (document.getElementById('commSearchInput')?.value || '').toLowerCase();

    let list = drivers.filter((d) => {
      const pending = parseFloat(d.pendingCommission) || 0;
      const unpaid = parseInt(d.unpaidTripsCount, 10) || 0;

      if (filter === 'due' && pending <= 0) return false;
      if (filter === 'locked' && unpaid < 3) return false;
      if (filter === 'settled' && pending > 0) return false;

      if (search) {
        const dName = getDriverName(d).toLowerCase();
        const dPhone = (d.phoneNumber || '').toLowerCase();
        const dPlate = (d.vehiclePlateNumber || '').toLowerCase();
        if (!dName.includes(search) && !dPhone.includes(search) && !dPlate.includes(search)) {
          return false;
        }
      }
      return true;
    });

    if (list.length === 0) {
      tbodyLedger.innerHTML = `<tr><td colspan="9" style="text-align:center; padding:36px; color:#64748B;">No driver commission records match filter.</td></tr>`;
    } else {
      let html = '';
      list.forEach((d) => {
        const dName = getDriverName(d);
        const trips = parseInt(d.totalTrips || 0, 10);
        const pending = parseFloat(d.pendingCommission || 0);
        const settled = parseFloat(d.totalCommissionSettled || 0);
        const unpaid = parseInt(d.unpaidTripsCount || 0, 10);

        // Approximate Gross from completed bookings or trip formula
        const driverCompletedRides = bookings.filter(b => b.driverId === d.id && (b.status === 'completed' || b.status === 'trip_completed'));
        const grossFromRides = driverCompletedRides.reduce((acc, b) => acc + (parseFloat(b.finalFare || b.estimatedFare) || 0), 0);
        const estimatedGross = grossFromRides > 0 ? grossFromRides : (trips * 450);
        const driverShare90 = estimatedGross * 0.90;

        const isLocked = unpaid >= 3;
        const lockBadge = isLocked
          ? `<span class="badge badge-danger"><i class="fa-solid fa-lock"></i> ${unpaid} / 3 LOCKED</span>`
          : (unpaid === 2 ? `<span class="badge badge-warning">${unpaid} / 3 Warning</span>` : `<span class="badge badge-neutral">${unpaid} / 3 OK</span>`);

        const dueClass = pending > 0 ? 'color:#DC2626; font-size:15px;' : 'color:#059669; font-size:15px;';

        html += `
          <tr>
            <td>
              <div style="display:flex; align-items:center; gap:10px;">
                <div style="width:36px; height:36px; border-radius:50%; background:#0F172A; color:#FEF08A; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:13px; flex-shrink:0;">
                  ${(dName[0] || 'D').toUpperCase()}
                </div>
                <div>
                  <strong style="display:block; font-size:14px; color:#0F172A;">${dName}</strong>
                  <span style="font-size:12px; color:#64748B;">ID: ${d.id.substring(0, 10)}</span>
                </div>
              </div>
            </td>
            <td>
              <a href="tel:${d.phoneNumber}" style="color:#059669; font-weight:700; text-decoration:none;">
                <i class="fa-solid fa-phone"></i> ${d.phoneNumber || 'N/A'}
              </a>
            </td>
            <td>
              <span class="badge-category">${(d.vehicleCategoryId || 'CAB').toUpperCase()}</span>
              <span style="display:block; font-size:12px; color:#475569; margin-top:2px;">${d.vehicleModel || ''}</span>
              <strong style="font-size:12px; color:#0F172A;">${d.vehiclePlateNumber || 'No Plate'}</strong>
            </td>
            <td><strong style="font-size:14px; color:#0F172A;">${trips}</strong></td>
            <td><strong style="font-size:14px; color:#0F172A;">₹${Math.round(estimatedGross).toLocaleString('en-IN')}</strong></td>
            <td><strong style="${dueClass}">₹${Math.round(pending).toLocaleString('en-IN')}</strong></td>
            <td><strong style="color:#059669; font-size:14px;">₹${Math.round(settled).toLocaleString('en-IN')}</strong></td>
            <td>${lockBadge}</td>
            <td style="text-align:right;">
              <button class="btn btn-primary btn-sm" onclick="openSettlePaymentModal('${d.id}')" title="Record settled payment">
                <i class="fa-solid fa-hand-holding-dollar"></i> Settle Payment
              </button>
            </td>
          </tr>
        `;
      });
      tbodyLedger.innerHTML = html;
    }
  }

  // 3. Render Settlement History Table
  const tbodyHistory = document.getElementById('settlementsHistoryTableBody');
  if (tbodyHistory) {
    if (settlements.length === 0) {
      tbodyHistory.innerHTML = `<tr><td colspan="7" style="text-align:center; padding:24px; color:#64748B;">No settlement records found yet. Use "Settle Payment" above to record cash or UPI collections.</td></tr>`;
    } else {
      let hHtml = '';
      settlements.forEach((s) => {
        const dateStr = s.settledAt ? (s.settledAt.seconds ? new Date(s.settledAt.seconds * 1000).toLocaleString('en-IN') : new Date(s.settledAt).toLocaleString('en-IN')) : 'N/A';
        const modeBadge = (s.paymentMode === 'cash')
          ? '<span class="badge badge-neutral"><i class="fa-solid fa-money-bill"></i> Cash</span>'
          : (s.paymentMode === 'upi' ? '<span class="badge badge-info"><i class="fa-solid fa-qrcode"></i> UPI</span>' : '<span class="badge badge-success"><i class="fa-solid fa-building-columns"></i> Bank/Wallet</span>');

        hHtml += `
          <tr>
            <td><strong style="font-family:monospace; color:#059669;">${s.transactionRef || s.id.substring(0, 10)}</strong></td>
            <td>${dateStr}</td>
            <td>
              <strong style="display:block;">${s.driverName || 'Driver Partner'}</strong>
              <span style="font-size:12px; color:#64748B;">${s.driverPhone || ''}</span>
            </td>
            <td><strong style="font-size:15px; color:#059669;">₹${parseFloat(s.amountSettled || 0).toLocaleString('en-IN')}</strong></td>
            <td>${modeBadge}</td>
            <td style="font-size:12.5px; color:#475569;">${s.notes || 'Settled'}</td>
            <td><span class="badge badge-success"><i class="fa-solid fa-shield-check"></i> ${s.settledBy || 'Admin HQ'}</span></td>
          </tr>
        `;
      });
      tbodyHistory.innerHTML = hHtml;
    }
  }
}

/**
 * 10. Payout Requests Table Controller
 */
function renderPayoutsTable() {
  const tbody = document.getElementById('payoutsTableBody');
  if (!tbody) return;

  const list = AdminStore.payouts;
  if (list.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" style="text-align:center; padding:36px; color:#64748B;">No payout requests found.</td></tr>`;
    return;
  }

  let html = '';
  list.forEach((p) => {
    const isPending = p.status === 'pending';
    const statusChip = isPending
      ? '<span class="badge badge-warning">Pending Disbursal</span>'
      : (p.status === 'approved' ? '<span class="badge badge-success">Approved / Paid</span>' : '<span class="badge badge-danger">Rejected</span>');

    const dName = p.driverName || 'Driver Partner';

    html += `
      <tr>
        <td><strong>#PAY-${p.id.substring(0, 6).toUpperCase()}</strong></td>
        <td>
          <strong style="display:block;">${dName}</strong>
          <span style="font-size:12px; color:#64748B;">${p.driverPhone || ''}</span>
        </td>
        <td><strong style="font-size:16px; color:#059669;">₹${parseFloat(p.amount || 0).toLocaleString('en-IN')}</strong></td>
        <td><span style="background:#F1F5F9; padding:4px 8px; border-radius:4px; font-family:monospace; font-weight:700;">${p.upiId || 'N/A'}</span></td>
        <td>${p.requestedAt ? new Date(p.requestedAt.seconds * 1000).toLocaleString('en-IN') : 'N/A'}</td>
        <td>${statusChip}</td>
        <td>
          ${isPending ? `
            <div class="action-btns">
              <button class="btn btn-success btn-sm" onclick="promptApprovePayout('${p.id}', ${p.amount}, '${p.upiId}')">
                <i class="fa-solid fa-check"></i> Pay UPI
              </button>
              <button class="btn btn-danger btn-sm" onclick="rejectPayout('${p.id}')">
                <i class="fa-solid fa-xmark"></i>
              </button>
            </div>
          ` : `<span style="font-size:12px; color:#64748B;">Ref: ${p.transactionRef || 'Direct Settle'}</span>`}
        </td>
      </tr>
    `;
  });

  tbody.innerHTML = html;
}

/**
 * 11. Remote App Updates View Controller
 */
function renderRemoteConfigView() {
  const cfg = AdminStore.remoteConfig;
  if (!cfg) return;

  const driverBuildInput = document.getElementById('cfgDriverBuild');
  const customerBuildInput = document.getElementById('cfgCustomerBuild');
  const forceUpdateCheckbox = document.getElementById('cfgForceUpdate');
  const apkUrlInput = document.getElementById('cfgDriverApkUrl');

  if (driverBuildInput) driverBuildInput.value = cfg.driverCurrentBuild || 26;
  if (customerBuildInput) customerBuildInput.value = cfg.customerCurrentBuild || 26;
  if (forceUpdateCheckbox) forceUpdateCheckbox.checked = Boolean(cfg.forceUpdate);
  if (apkUrlInput) apkUrlInput.value = cfg.driverApkUrl || 'https://districtcar.in/build_outputs/DistrictCar_Driver_Release.apk';
  
  const guestPopupCheckbox = document.getElementById('cfgGuestSignInPopup');
  if (guestPopupCheckbox) {
    // Enabled by default unless explicitly set to false
    guestPopupCheckbox.checked = (cfg.showGuestSignInPopup !== false);
  }
  updateGuestPopupUI(cfg.showGuestSignInPopup !== false);
}

/**
 * 12. Modal Handlers
 */
let activeModalDriverId = null;
let activeModalBookingId = null;

function openDriverModal(driverId) {
  activeModalDriverId = driverId;
  const d = AdminStore.drivers.find(x => x.id === driverId);
  if (!d) return;

  const dName = getDriverName(d);
  safeSetText('modalDriverName', dName);
  safeSetText('modalDriverPhone', d.phoneNumber || 'N/A');
  safeSetText('modalDriverPlate', d.vehiclePlateNumber || 'N/A');
  safeSetText('modalDriverCategory', (d.vehicleCategoryId || 'CAB').toUpperCase());
  safeSetText('modalDriverDL', d.dlNumber || 'N/A');
  safeSetText('modalDriverWallet', `₹${(d.walletBalance || 0).toLocaleString('en-IN')}`);
  safeSetText('modalDriverCommission', `₹${(d.pendingCommission || 0).toLocaleString('en-IN')}`);
  safeSetText('modalDriverTrips', `${d.totalTrips || 0} Trips`);

  // Document Photos preview
  const dlImg = document.getElementById('modalDriverDlImg');
  const rcImg = document.getElementById('modalDriverRcImg');
  if (dlImg) dlImg.src = d.dlPhotoUrl || 'https://placehold.co/400x250/e2e8f0/475569?text=No+DL+Uploaded';
  if (rcImg) rcImg.src = d.rcPhotoUrl || 'https://placehold.co/400x250/e2e8f0/475569?text=No+RC+Uploaded';

  openModal('driverDetailModal');
}

/**
 * Time & Date Formatting Helpers
 */
function formatTimestamp(ts) {
  if (!ts) return null;
  const d = ts.seconds ? new Date(ts.seconds * 1000) : (ts instanceof Date ? ts : new Date(ts));
  if (isNaN(d.getTime())) return null;

  return d.toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit'
  });
}

function getTimeDiffMinutes(startTs, endTs) {
  if (!startTs || !endTs) return null;
  const t1 = startTs.seconds ? startTs.seconds * 1000 : new Date(startTs).getTime();
  const t2 = endTs.seconds ? endTs.seconds * 1000 : new Date(endTs).getTime();
  const diffMs = t2 - t1;
  if (isNaN(diffMs) || diffMs < 0) return null;
  return Math.round(diffMs / 60000);
}

/**
 * Generates Available Driver <option> list for manual ride dispatch
 */
function getAvailableDriverOptions(selectedCategoryId = '') {
  const drivers = AdminStore.drivers || [];
  // Sort so online/idle drivers come first
  const sorted = [...drivers].sort((a, b) => {
    if (a.isOnline && !b.isOnline) return -1;
    if (!a.isOnline && b.isOnline) return 1;
    return 0;
  });

  return sorted.map(d => {
    const dName = getDriverName(d);
    const cat = (d.vehicleCategoryId || 'CAB').toUpperCase();
    const plate = d.vehiclePlateNumber || 'No Plate';
    const status = d.driverStatus === 'busy' ? 'Busy' : (d.isOnline ? 'Online' : 'Offline');
    const isCatMatch = selectedCategoryId && (d.vehicleCategoryId || '').toLowerCase() === selectedCategoryId.toLowerCase();
    const matchPrefix = isCatMatch ? '★ ' : '';
    return `<option value="${d.id}">${matchPrefix}${dName} (${cat} • ${plate} - ${status})</option>`;
  }).join('');
}

/**
 * Quick Manual Driver Assignment Handler from Rides Table
 */
/**
 * Cancel Booking Handler from Rides Table or Direct Button
 */
async function handleCancelBooking(bookingId) {
  const b = AdminStore.bookings.find(x => x.id === bookingId);
  const rideIdStr = b ? (b.readableId || b.id.substring(0, 8)) : bookingId;

  if (!confirm('Are you sure you want to cancel booking ' + rideIdStr + '?')) {
    return;
  }

  try {
    await apiCancelBooking(bookingId, 'Cancelled by Admin HQ');
    showToast('Booking ' + rideIdStr + ' cancelled successfully!');
    renderAllViews();
    if (activeModalBookingId === bookingId) {
      openBookingAuditModal(bookingId);
    }
  } catch (err) {
    alert('Failed to cancel booking: ' + err.message);
  }
}

async function handleCancelBookingFromModal() {
  if (!activeModalBookingId) return;
  await handleCancelBooking(activeModalBookingId);
}

async function handleQuickAssign(bookingId) {
  const selectEl = document.getElementById(`assignSelect_${bookingId}`);
  if (!selectEl) return;
  const driverId = selectEl.value;
  if (!driverId) {
    return alert('Please select an available driver from the dropdown first.');
  }

  const d = AdminStore.drivers.find(x => x.id === driverId);
  const dName = d ? getDriverName(d) : 'selected driver';

  if (!confirm(`Are you sure you want to manually assign driver "${dName}" to this booking?`)) return;

  try {
    await apiAssignDriverToBooking(bookingId, driverId);
    showToast(`Driver "${dName}" manually assigned to ride!`);
    renderAllViews();
  } catch (err) {
    alert('Failed to assign driver: ' + err.message);
  }
}

/**
 * Manual Driver Assignment Handler from Modal
 */
async function handleModalAssignDriver() {
  if (!activeModalBookingId) return;
  const selectEl = document.getElementById('modalDriverSelect');
  if (!selectEl) return;
  const driverId = selectEl.value;
  if (!driverId) {
    return alert('Please select a driver partner to assign.');
  }

  const d = AdminStore.drivers.find(x => x.id === driverId);
  const dName = d ? getDriverName(d) : 'driver partner';

  try {
    await apiAssignDriverToBooking(activeModalBookingId, driverId);
    showToast(`Driver "${dName}" assigned to ride!`);
    openBookingAuditModal(activeModalBookingId);
    renderAllViews();
  } catch (err) {
    alert('Failed to assign driver: ' + err.message);
  }
}

function openBookingAuditModal(bookingId) {
  activeModalBookingId = bookingId;
  const b = AdminStore.bookings.find(x => x.id === bookingId);
  if (!b) return;

  const dName = b.driverName ? b.driverName : (b.driverId ? `Driver #${b.driverId.substring(0, 6)}` : 'Unassigned');

  safeSetText('auditBookingId', b.readableId || b.id);
  safeSetText('auditCustomer', `${b.customerName || 'Customer'} (${b.customerPhone || 'N/A'})`);
  safeSetText('auditDriver', `${dName} ${b.driverPhone ? `(${b.driverPhone})` : ''}`);
  safeSetText('auditPickup', b.pickup?.address || 'N/A');
  safeSetText('auditDestination', b.destination?.address || 'N/A');
  safeSetText('auditOTP', b.rideOtp || 'N/A');
  const modalDistKm = getBookingDistanceKm(b);
  safeSetText('auditDistance', modalDistKm !== null ? `${modalDistKm} km ${b.isRoundTrip ? '(Round Trip)' : ''}` : 'Direct City/Rural Route');

  const bTime = formatTimestamp(b.createdAt) || 'Recent';
  safeSetText('auditBookingTime', bTime);

  const aTime = formatTimestamp(b.driverAcceptedAt || b.acceptedAt);
  const diffMins = getTimeDiffMinutes(b.createdAt, b.driverAcceptedAt || b.acceptedAt);
  if (aTime) {
    safeSetText('auditAcceptTime', `${aTime} ${diffMins !== null ? `(+${diffMins} mins)` : ''}`);
  } else {
    safeSetText('auditAcceptTime', b.status.includes('cancelled') ? 'Cancelled' : 'Not Accepted Yet');
  }

  // If unassigned, show assign dropdown in modal
  const assignSec = document.getElementById('modalAssignDriverSection');
  const modalSelect = document.getElementById('modalDriverSelect');
  if (assignSec && modalSelect) {
    if (!b.driverId && !b.status.includes('cancelled')) {
      assignSec.style.display = 'block';
      modalSelect.innerHTML = `<option value="">-- Choose Driver Partner --</option>` + getAvailableDriverOptions(b.vehicleCategoryId);
    } else {
      assignSec.style.display = 'none';
    }
  }

  const modalCancelBtn = document.getElementById('modalCancelBookingBtn');
  if (modalCancelBtn) {
    if (!b.status.includes('cancelled') && b.status !== 'completed' && b.status !== 'trip_completed') {
      modalCancelBtn.style.display = 'inline-flex';
    } else {
      modalCancelBtn.style.display = 'none';
    }
  }

  const gross = parseFloat(b.finalFare || b.estimatedFare || 0);
  safeSetText('auditGrossFare', `₹${gross.toFixed(0)}`);
  safeSetText('auditCommission', `₹${(gross * 0.10).toFixed(0)} (10%)`);
  safeSetText('auditDriverNet', `₹${(gross * 0.90).toFixed(0)} (90%)`);

  openModal('bookingAuditModal');
}

/**
 * Settle Payment Modal Controller
 */
function openSettlePaymentModal(driverId) {
  const d = AdminStore.drivers.find(x => x.id === driverId);
  if (!d) return;

  const dName = getDriverName(d);
  const pending = parseFloat(d.pendingCommission || 0);

  document.getElementById('settleDriverId').value = d.id;
  safeSetText('settleModalDriverName', dName);
  safeSetText('settleModalDriverPhone', d.phoneNumber || 'N/A');
  safeSetText('settleModalDriverPlate', `${(d.vehicleCategoryId || 'CAB').toUpperCase()} • ${d.vehiclePlateNumber || 'No Plate'}`);
  safeSetText('settleModalCurrentDue', `₹${pending.toLocaleString('en-IN')}`);

  const amountInput = document.getElementById('settleAmountInput');
  if (amountInput) {
    amountInput.value = pending > 0 ? pending : 0;
    amountInput.max = pending > 0 ? pending * 2 : 5000;
  }

  const refInput = document.getElementById('settleRefInput');
  if (refInput) {
    refInput.value = `CASH-REC-${Math.floor(Math.random() * 8999 + 1000)}`;
  }

  const notesInput = document.getElementById('settleNotesInput');
  if (notesInput) {
    notesInput.value = `Platform 10% fee settlement. Unpaid cash trips reset to 0.`;
  }

  openModal('settlePaymentModal');
}

async function handleConfirmSettlement(e) {
  e.preventDefault();
  const driverId = document.getElementById('settleDriverId').value;
  const amount = parseFloat(document.getElementById('settleAmountInput').value);
  const paymentMode = document.getElementById('settleModeSelect').value;
  const refNo = document.getElementById('settleRefInput').value;
  const notes = document.getElementById('settleNotesInput').value;

  if (isNaN(amount) || amount <= 0) {
    return alert('Please enter a valid amount greater than ₹0.');
  }

  const d = AdminStore.drivers.find(x => x.id === driverId);
  const dName = d ? getDriverName(d) : 'Driver Partner';

  try {
    await apiSettleDriverCommissionFull(driverId, amount, paymentMode, refNo, notes);
    showToast(`₹${amount} Commission settled for ${dName}! 3-Trip lock cleared.`);
    closeModal('settlePaymentModal');
    renderAllViews();
  } catch (err) {
    alert('Failed to settle commission: ' + err.message);
  }
}

function openModal(modalId) {
  const el = document.getElementById(modalId);
  if (el) el.classList.add('active');
}

function closeModal(modalId) {
  const el = document.getElementById(modalId);
  if (el) el.classList.remove('active');
}

/**
 * Action Handlers
 */
async function approveDriverKYC(driverId) {
  const d = AdminStore.drivers.find(x => x.id === driverId);
  const dName = d ? getDriverName(d) : 'Driver';
  if (!confirm(`Are you sure you want to approve driver partner ${dName}?`)) return;

  try {
    await apiUpdateDriverVerification(driverId, 'approved');
    showToast(`Driver ${dName} approved successfully!`);
    closeModal('driverDetailModal');
    renderAllViews();
  } catch (e) {
    alert('Failed to approve driver: ' + e.message);
  }
}

async function rejectDriverKYC(driverId) {
  const reason = prompt('Please enter rejection reason (e.g. Expired DL / Blur RC):', 'Documents blurry or incomplete');
  if (!reason) return;
  try {
    await apiUpdateDriverVerification(driverId, 'rejected', reason);
    showToast('Driver KYC marked as rejected.');
    closeModal('driverDetailModal');
    renderAllViews();
  } catch (e) {
    alert('Failed to reject driver: ' + e.message);
  }
}

async function toggleUserBlock(userId, currentBlocked) {
  const actionStr = currentBlocked ? 'unblock' : 'block';
  if (!confirm(`Are you sure you want to ${actionStr} this customer account?`)) return;
  try {
    await apiToggleUserBlock(userId, currentBlocked);
    showToast(`User successfully ${actionStr}ed.`);
    renderUsersTable();
  } catch (e) {
    alert('Failed to update user: ' + e.message);
  }
}

/**
 * Delete Handlers for Drivers, Users, and Bookings
 */
async function deleteDriver(driverId) {
  const d = AdminStore.drivers.find(x => x.id === driverId);
  const dName = d ? getDriverName(d) : 'this driver partner';

  if (!confirm(`⚠️ PERMANENT DELETION WARNING:\n\nAre you sure you want to permanently delete driver "${dName}"?\n\nThis will remove their driver profile, KYC records, and vehicle data from Firestore. This action CANNOT be undone.`)) {
    return;
  }

  try {
    await apiDeleteDriver(driverId);
    showToast(`Driver "${dName}" permanently deleted.`);
    closeModal('driverDetailModal');
    renderAllViews();
  } catch (err) {
    alert('Failed to delete driver: ' + err.message);
  }
}

function deleteDriverFromModal() {
  if (activeModalDriverId) {
    deleteDriver(activeModalDriverId);
  }
}

async function deleteUser(userId) {
  const u = AdminStore.users.find(x => x.id === userId);
  const uName = u ? (u.displayName || u.name || 'this customer') : 'this customer';

  if (!confirm(`⚠️ PERMANENT DELETION WARNING:\n\nAre you sure you want to permanently delete customer "${uName}"?\n\nThis will delete their customer profile from Firestore. This action CANNOT be undone.`)) {
    return;
  }

  try {
    await apiDeleteUser(userId);
    showToast(`Customer "${uName}" permanently deleted.`);
    renderAllViews();
  } catch (err) {
    alert('Failed to delete user: ' + err.message);
  }
}

async function deleteBooking(bookingId) {
  const b = AdminStore.bookings.find(x => x.id === bookingId);
  const rId = b ? (b.readableId || b.id.substring(0, 8)) : bookingId;

  if (!confirm(`⚠️ PERMANENT DELETION WARNING:\n\nAre you sure you want to permanently delete booking "${rId}"?\n\nThis will permanently delete this ride transaction record from Firestore. This action CANNOT be undone.`)) {
    return;
  }

  try {
    await apiDeleteBooking(bookingId);
    showToast(`Booking "${rId}" permanently deleted.`);
    closeModal('bookingAuditModal');
    renderAllViews();
  } catch (err) {
    alert('Failed to delete booking: ' + err.message);
  }
}

function deleteBookingFromModal() {
  if (activeModalBookingId) {
    deleteBooking(activeModalBookingId);
  }
}

async function promptApprovePayout(payoutId, amount, upiId) {
  const utr = prompt(`Disburse ₹${amount} to UPI: ${upiId}\nEnter Bank UTR / Transaction Reference Number:`, 'UPI' + Math.floor(Math.random() * 899999 + 100000));
  if (!utr) return;

  try {
    await apiProcessPayout(payoutId, 'approved', utr);
    showToast(`Payout of ₹${amount} marked as paid (UTR: ${utr})!`);
    renderPayoutsTable();
  } catch (e) {
    alert('Failed to process payout: ' + e.message);
  }
}

async function rejectPayout(payoutId) {
  if (!confirm('Reject this payout request?')) return;
  try {
    await apiProcessPayout(payoutId, 'rejected', 'Rejected by admin');
    showToast('Payout request rejected.');
    renderPayoutsTable();
  } catch (e) {
    alert('Failed to reject payout: ' + e.message);
  }
}

async function saveRemoteConfigForm(e) {
  e.preventDefault();
  const dBuild = document.getElementById('cfgDriverBuild').value;
  const cBuild = document.getElementById('cfgCustomerBuild').value;
  const force = document.getElementById('cfgForceUpdate').checked;
  const apk = document.getElementById('cfgDriverApkUrl').value;
  const guestPopup = document.getElementById('cfgGuestSignInPopup') ? document.getElementById('cfgGuestSignInPopup').checked : true;

  try {
    await apiSaveRemoteConfig(dBuild, cBuild, force, apk, guestPopup);
    showToast(`Remote config updated! Driver v${dBuild}, Customer v${cBuild}, Guest Popup: ${guestPopup ? 'ON' : 'OFF'}`);
  } catch (e) {
    alert('Failed to save configuration: ' + e.message);
  }
}

/**
 * Standalone direct button handlers for Customer App Guest Sign-In Popup
 */
async function setGuestSignInPopupDirect(enabled) {
  try {
    await apiSetGuestSignInPopup(enabled);
    updateGuestPopupUI(enabled);
    showToast(enabled ? 'Popup Sign-In turned ON for all customer apps!' : 'Popup Sign-In turned OFF remotely.');
  } catch (e) {
    alert('Failed to update popup status: ' + e.message);
  }
}

async function toggleGuestSignInPopupDirectly() {
  const cfg = AdminStore.remoteConfig || {};
  const currentlyOn = (cfg.showGuestSignInPopup !== false);
  await setGuestSignInPopupDirect(!currentlyOn);
}

function updateGuestPopupUI(enabled) {
  const isEnabled = enabled !== undefined ? Boolean(enabled) : ((AdminStore.remoteConfig?.showGuestSignInPopup) !== false);

  // 1. Topbar Button & Status
  const topbarStatus = document.getElementById('topbarGuestPopupStatus');
  const topbarBtn = document.getElementById('topbarGuestPopupBtn');
  if (topbarStatus) topbarStatus.textContent = isEnabled ? 'ON' : 'OFF';
  if (topbarBtn) {
    if (isEnabled) {
      topbarBtn.style.background = '#ECFDF5';
      topbarBtn.style.color = '#059669';
      topbarBtn.style.borderColor = '#A7F3D0';
    } else {
      topbarBtn.style.background = '#FEF2F2';
      topbarBtn.style.color = '#DC2626';
      topbarBtn.style.borderColor = '#FECACA';
    }
  }

  // 2. Dashboard Button & Status
  const dashStatus = document.getElementById('dashGuestPopupStatus');
  const dashBtn = document.getElementById('dashGuestPopupBtn');
  if (dashStatus) dashStatus.textContent = isEnabled ? 'ON' : 'OFF';
  if (dashBtn) {
    if (isEnabled) {
      dashBtn.style.color = '#059669';
      dashBtn.style.borderColor = '#A7F3D0';
    } else {
      dashBtn.style.color = '#DC2626';
      dashBtn.style.borderColor = '#FECACA';
    }
  }

  // 3. Standalone Status Badge in Updates view
  const badge = document.getElementById('guestPopupStatusBadge');
  if (badge) {
    if (isEnabled) {
      badge.innerHTML = '<i class="fa-solid fa-circle-check"></i> ACTIVE (ON)';
      badge.style.background = '#ECFDF5';
      badge.style.color = '#059669';
      badge.style.borderColor = '#A7F3D0';
    } else {
      badge.innerHTML = '<i class="fa-solid fa-circle-xmark"></i> DISABLED (OFF)';
      badge.style.background = '#FEF2F2';
      badge.style.color = '#DC2626';
      badge.style.borderColor = '#FECACA';
    }
  }

  // 4. Form Checkbox
  const checkbox = document.getElementById('cfgGuestSignInPopup');
  if (checkbox) {
    checkbox.checked = isEnabled;
  }
}

/**
 * 13. Search & Filter Handlers
 */
function setupSearch() {
  const bindSearch = (inputId, renderFn) => {
    const el = document.getElementById(inputId);
    if (el) {
      el.addEventListener('input', () => renderFn());
    }
  };

  bindSearch('driverSearchInput', renderDriversTable);
  bindSearch('userSearchInput', renderUsersTable);
  bindSearch('bookingSearchInput', renderBookingsTable);
  bindSearch('commSearchInput', renderCommissionView);

  const globalSearch = document.getElementById('globalSearchInput');
  if (globalSearch) {
    globalSearch.addEventListener('input', (e) => {
      const term = e.target.value.toLowerCase();
      if (!term) return;

      if (term.includes('dc-') || term.includes('#')) {
        switchView('bookings');
        const bInput = document.getElementById('bookingSearchInput');
        if (bInput) bInput.value = term;
        renderBookingsTable();
      } else {
        switchView('drivers');
        const dInput = document.getElementById('driverSearchInput');
        if (dInput) dInput.value = term;
        renderDriversTable();
      }
    });
  }
}

/**
 * 14. CSV Exports
 */
function exportBookingsCSV() {
  const list = AdminStore.bookings;
  if (list.length === 0) return alert('No bookings to export.');

  let csv = 'BookingID,Date,CustomerName,CustomerPhone,DriverName,Category,TotalDistanceKm,Status,GrossFare,Commission10,DriverNet90,PaymentMethod\n';
  list.forEach(b => {
    const gross = parseFloat(b.finalFare || b.estimatedFare || 0);
    const dateStr = b.createdAt ? new Date(b.createdAt.seconds ? b.createdAt.seconds * 1000 : b.createdAt).toISOString() : '';
    const rowDist = getBookingDistanceKm(b) || 'N/A';
    csv += `"${b.readableId || b.id}","${dateStr}","${b.customerName || ''}","${b.customerPhone || ''}","${b.driverName || ''}","${b.vehicleCategoryId || ''}","${rowDist}","${b.status}","${gross}","${(gross*0.1).toFixed(0)}","${(gross*0.9).toFixed(0)}","${b.paymentMethod || 'cash'}"\n`;
  });

  downloadCSV(csv, `DistrictCar_Bookings_Report_${new Date().toISOString().split('T')[0]}.csv`);
}

function exportCommissionCSV() {
  const list = AdminStore.drivers;
  if (list.length === 0) return alert('No driver data to export.');

  let csv = 'DriverID,DriverName,PhoneNumber,VehiclePlate,Category,TotalTrips,CommissionDue,CommissionSettled,UnpaidTrips,3TripLocked\n';
  list.forEach(d => {
    const dName = getDriverName(d);
    const unpaid = parseInt(d.unpaidTripsCount || 0, 10);
    csv += `"${d.id}","${dName}","${d.phoneNumber || ''}","${d.vehiclePlateNumber || ''}","${d.vehicleCategoryId || ''}","${d.totalTrips || 0}","${d.pendingCommission || 0}","${d.totalCommissionSettled || 0}","${unpaid}","${unpaid >= 3 ? 'YES' : 'NO'}"\n`;
  });

  downloadCSV(csv, `DistrictCar_Driver_Commission_Ledger_${new Date().toISOString().split('T')[0]}.csv`);
}

function downloadCSV(csvContent, filename) {
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = filename;
  link.click();
}

/**
 * Utilities
 */
function safeSetText(id, text) {
  const el = document.getElementById(id);
  if (el) el.innerText = text;
}

function showToast(msg) {
  const container = document.getElementById('toastContainer');
  if (!container) return;

  const t = document.createElement('div');
  t.className = 'toast';
  t.innerHTML = `<i class="fa-solid fa-circle-check" style="color:#10B981; font-size:16px;"></i> ${msg}`;
  container.appendChild(t);

  setTimeout(() => {
    t.style.opacity = '0';
    t.style.transform = 'translateX(100%)';
    setTimeout(() => t.remove(), 300);
  }, 3500);
}


/**
 * 15. Master Security PIN Lock Controller (PIN: 564100)
 */
const MASTER_ADMIN_PIN = '564100';

function setupPinLock() {
  const overlay = document.getElementById('pinLockOverlay');
  if (!overlay) return;

  // Check existing session
  if (sessionStorage.getItem('dc_admin_unlocked') === 'true') {
    overlay.classList.add('unlocked');
  } else {
    overlay.classList.remove('unlocked');
    setTimeout(() => {
      const p1 = document.getElementById('p1');
      if (p1) p1.focus();
    }, 250);
  }

  // Setup 6-digit auto-advancing inputs
  const digits = [
    document.getElementById('p1'),
    document.getElementById('p2'),
    document.getElementById('p3'),
    document.getElementById('p4'),
    document.getElementById('p5'),
    document.getElementById('p6')
  ];

  digits.forEach((input, idx) => {
    if (!input) return;

    input.addEventListener('input', (e) => {
      const val = e.target.value;
      if (val.length >= 1) {
        input.value = val.slice(-1);
        if (idx < digits.length - 1) {
          digits[idx + 1].focus();
        } else {
          verifyPin();
        }
      }
    });

    input.addEventListener('keydown', (e) => {
      if (e.key === 'Backspace') {
        if (!input.value && idx > 0) {
          digits[idx - 1].focus();
          digits[idx - 1].value = '';
        } else {
          input.value = '';
        }
      }
    });

    // Support paste of entire 6-digit PIN
    input.addEventListener('paste', (e) => {
      e.preventDefault();
      const pasteData = (e.clipboardData || window.clipboardData).getData('text').trim();
      if (/^\d{6}$/.test(pasteData)) {
        pasteData.split('').forEach((char, i) => {
          if (digits[i]) digits[i].value = char;
        });
        verifyPin();
      }
    });
  });
}

function handlePinSubmit(e) {
  if (e) e.preventDefault();
  verifyPin();
}

function verifyPin() {
  const digits = ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'].map(id => document.getElementById(id)?.value || '').join('');
  const errorMsg = document.getElementById('pinErrorMsg');
  const card = document.getElementById('pinCard');
  const overlay = document.getElementById('pinLockOverlay');

  if (digits === MASTER_ADMIN_PIN) {
    if (errorMsg) errorMsg.innerHTML = '';
    sessionStorage.setItem('dc_admin_unlocked', 'true');
    if (overlay) overlay.classList.add('unlocked');
    showToast('Master Admin unlocked! Welcome to District Car HQ. 🚀');
  } else {
    if (errorMsg) {
      errorMsg.innerHTML = '<i class="fa-solid fa-circle-xmark"></i> Invalid Security PIN. Access Denied.';
    }
    if (card) {
      card.classList.add('shake');
      setTimeout(() => card.classList.remove('shake'), 450);
    }
    // Clear inputs and refocus
    ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'].forEach(id => {
      const el = document.getElementById(id);
      if (el) el.value = '';
    });
    const p1 = document.getElementById('p1');
    if (p1) p1.focus();
  }
}

function lockAdminDashboard() {
  sessionStorage.removeItem('dc_admin_unlocked');
  const overlay = document.getElementById('pinLockOverlay');
  if (overlay) overlay.classList.remove('unlocked');
  ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.value = '';
  });
  const errorMsg = document.getElementById('pinErrorMsg');
  if (errorMsg) errorMsg.innerHTML = '';
  const p1 = document.getElementById('p1');
  if (p1) p1.focus();
  showToast('Dashboard locked.');
}


/* =========================================================================
 * 13. DYNAMIC PRICING, CATEGORIES & SDUI FESTIVE THEME STUDIO
 * ========================================================================= */

const DEFAULT_CATEGORIES = [
  { id: 'car', name: 'Mini Cab', displayName: 'Economy Mini Cab', baseFare: 0, perKmRate: 15, minimumFare: 60, hourlyWaitingCharge: 60, cancellationFee: 30 },
  { id: 'auto', name: 'Auto / E-Rick', displayName: 'Auto', baseFare: 0, perKmRate: 11, minimumFare: 40, hourlyWaitingCharge: 40, cancellationFee: 20 },
  { id: 'sedan', name: 'Sedan', displayName: 'Comfort Sedan', baseFare: 0, perKmRate: 23, minimumFare: 80, hourlyWaitingCharge: 60, cancellationFee: 40 },
  { id: 'suv', name: 'SUV', displayName: 'SUV', baseFare: 0, perKmRate: 21, minimumFare: 100, hourlyWaitingCharge: 60, cancellationFee: 50 },
  { id: 'bike', name: 'Bike', displayName: 'Gramin Bike', baseFare: 25, perKmRate: 8, minimumFare: 35, hourlyWaitingCharge: 30, cancellationFee: 15 }
];

/**
 * Render Category Pricing & Dynamic Rules View
 */
function renderPricingView() {
  const rules = AdminStore.pricingRules || {};

  // 1. Populate Pricing Rules Inputs
  const elMinCap = document.getElementById('ruleMinDistanceCapKm');
  if (elMinCap && !elMinCap.matches(':focus')) {
    elMinCap.value = rules.minDistanceCapKm ?? 5.0;
  }

  const elShortCap = document.getElementById('ruleShortTripMaxDistanceKm');
  if (elShortCap && !elShortCap.matches(':focus')) {
    elShortCap.value = rules.shortTripMaxDistanceKm ?? 25.0;
  }

  const elShortSurge = document.getElementById('ruleShortTripSurgePercent');
  if (elShortSurge && !elShortSurge.matches(':focus')) {
    elShortSurge.value = rules.shortTripSurgePercent ?? 10.0;
  }

  const elShortComm = document.getElementById('ruleShortTripCommissionPercent');
  if (elShortComm && !elShortComm.matches(':focus')) {
    elShortComm.value = rules.shortTripCommissionPercent ?? 18.0;
  }

  const elLongComm = document.getElementById('ruleLongTripCommissionPercent');
  if (elLongComm && !elLongComm.matches(':focus')) {
    elLongComm.value = rules.longTripCommissionPercent ?? 10.0;
  }

  const elShortComp = document.getElementById('ruleShortOneWayCompPercent');
  if (elShortComp && !elShortComp.matches(':focus')) {
    elShortComp.value = rules.shortTripOneWayCompensationPercent ?? 20.0;
  }

  const elLongComp = document.getElementById('ruleLongOneWayCompPercent');
  if (elLongComp && !elLongComp.matches(':focus')) {
    elLongComp.value = rules.longTripOneWayCompensationPercent ?? 40.0;
  }

  const elRoundDiscount = document.getElementById('ruleRoundTripDiscountPercent');
  if (elRoundDiscount && !elRoundDiscount.matches(':focus')) {
    elRoundDiscount.value = rules.roundTripDiscountPercent ?? 35.0;
  }

  // 2. Surge Fee Switch & Badges
  updateSurgeFeeUI(rules.adminSurgeEnabled === true);

  // 3. Render Vehicle Categories Fares Table
  renderCategoryPricingTable();

  // 4. Populate SDUI Festive Theme Studio
  syncFestiveThemeToUI(AdminStore.festiveTheme);
}

/**
 * Render Vehicle Category Fares Table
 */
function renderCategoryPricingTable() {
  const tbody = document.getElementById('categoryPricingTableBody');
  if (!tbody) return;

  const categories = (AdminStore.categories && AdminStore.categories.length > 0)
    ? AdminStore.categories
    : DEFAULT_CATEGORIES;

  const badgeEl = document.getElementById('categoryCountBadge');
  if (badgeEl) {
    badgeEl.innerText = `${categories.length} Active Classes`;
  }

  let html = '';
  categories.forEach((cat) => {
    const id = cat.id || 'cab';
    const name = cat.displayName || cat.name || id;
    const baseFare = cat.baseFare !== undefined ? cat.baseFare : 0;
    const perKmRate = cat.perKmRate !== undefined ? cat.perKmRate : 15;
    const minimumFare = cat.minimumFare !== undefined ? cat.minimumFare : 60;
    const hourlyWaiting = cat.hourlyWaitingCharge !== undefined ? cat.hourlyWaitingCharge : 60;

    let iconHtml = '<i class="fa-solid fa-car"></i>';
    const lower = (id + ' ' + name).toLowerCase();
    if (lower.includes('auto') || lower.includes('rick')) iconHtml = '<i class="fa-solid fa-bolt"></i>';
    else if (lower.includes('bike')) iconHtml = '<i class="fa-solid fa-motorcycle"></i>';
    else if (lower.includes('suv')) iconHtml = '<i class="fa-solid fa-truck-monster"></i>';
    else if (lower.includes('sedan')) iconHtml = '<i class="fa-solid fa-taxi"></i>';

    html += `
      <tr>
        <td>
          <div style="display:flex; align-items:center; gap:8px;">
            <span style="display:inline-flex; align-items:center; justify-content:center; width:28px; height:28px; border-radius:6px; background:#F1F5F9; color:#0F172A;">
              ${iconHtml}
            </span>
            <div>
              <strong style="color:#0F172A; display:block;">${escapeHTML(name)}</strong>
              <span style="font-size:11px; color:#64748B;">ID: ${escapeHTML(id)}</span>
            </div>
          </div>
        </td>
        <td><strong>₹${baseFare}</strong></td>
        <td><strong style="color:var(--primary);">₹${perKmRate}</strong>/km</td>
        <td>₹${minimumFare}</td>
        <td>₹${hourlyWaiting}/hr</td>
        <td>
          <button class="btn btn-sm btn-outline" onclick="openEditCategoryModal('${escapeHTML(id)}')">
            <i class="fa-solid fa-pen-to-square"></i> Edit
          </button>
        </td>
      </tr>
    `;
  });

  tbody.innerHTML = html;
}

/**
 * Topbar & Switch Surge Fee Quick Toggles
 */
function updateSurgeFeeUI(isEnabled) {
  const topbarBtn = document.getElementById('topbarSurgeFeeBtn');
  const topbarStatus = document.getElementById('topbarSurgeFeeStatus');
  const checkbox = document.getElementById('ruleAdminSurgeToggle');

  if (topbarStatus) {
    topbarStatus.innerText = isEnabled ? 'ON' : 'OFF';
  }
  if (topbarBtn) {
    if (isEnabled) {
      topbarBtn.style.background = '#ECFDF5';
      topbarBtn.style.borderColor = '#10B981';
      topbarBtn.style.color = '#047857';
    } else {
      topbarBtn.style.background = '#FFFBEB';
      topbarBtn.style.borderColor = '#FDE68A';
      topbarBtn.style.color = '#B45309';
    }
  }

  if (checkbox && checkbox.checked !== isEnabled) {
    checkbox.checked = isEnabled;
  }
}

async function toggleSurgeFeeDirectly() {
  const current = AdminStore.pricingRules?.adminSurgeEnabled === true;
  const next = !current;
  try {
    await apiToggleSurgeFee(next);
    updateSurgeFeeUI(next);
    showToast(`⚡ Surge Fee (+8% Platform Fee) set to ${next ? 'ON' : 'OFF'}`);
  } catch (e) {
    showToast(`Error toggling surge fee: ${e.message}`, 'error');
  }
}

async function toggleSurgeFeeFromCheckbox(checked) {
  try {
    await apiToggleSurgeFee(checked);
    updateSurgeFeeUI(checked);
    showToast(`⚡ Surge Fee (+8% Platform Fee) set to ${checked ? 'ON' : 'OFF'}`);
  } catch (e) {
    showToast(`Error toggling surge fee: ${e.message}`, 'error');
  }
}

/**
 * Save Dynamic Pricing Rules to Firestore
 */
async function saveAllPricingRulesFromForm() {
  const rules = {
    minDistanceCapKm: parseFloat(document.getElementById('ruleMinDistanceCapKm')?.value) || 5.0,
    shortTripMaxDistanceKm: parseFloat(document.getElementById('ruleShortTripMaxDistanceKm')?.value) || 25.0,
    shortTripSurgePercent: parseFloat(document.getElementById('ruleShortTripSurgePercent')?.value) || 10.0,
    shortTripCommissionPercent: parseFloat(document.getElementById('ruleShortTripCommissionPercent')?.value) || 18.0,
    longTripCommissionPercent: parseFloat(document.getElementById('ruleLongTripCommissionPercent')?.value) || 10.0,
    shortTripOneWayCompensationPercent: parseFloat(document.getElementById('ruleShortOneWayCompPercent')?.value) || 20.0,
    longTripOneWayCompensationPercent: parseFloat(document.getElementById('ruleLongOneWayCompPercent')?.value) || 40.0,
    roundTripDiscountPercent: parseFloat(document.getElementById('ruleRoundTripDiscountPercent')?.value) || 35.0,
    adminSurgeEnabled: Boolean(document.getElementById('ruleAdminSurgeToggle')?.checked),
    adminSurgePercent: 8.0,
  };

  try {
    await apiSavePricingRules(rules);
    showToast('✅ Dynamic Pricing Rules updated and published live to apps!');
  } catch (e) {
    showToast(`Failed to save pricing rules: ${e.message}`, 'error');
  }
}

/**
 * Edit Vehicle Category Fares Modal
 */
function openEditCategoryModal(catId) {
  const categories = (AdminStore.categories && AdminStore.categories.length > 0)
    ? AdminStore.categories
    : DEFAULT_CATEGORIES;

  const cat = categories.find(c => c.id === catId) || DEFAULT_CATEGORIES.find(c => c.id === catId) || { id: catId };

  document.getElementById('editCatId').value = cat.id || catId;
  document.getElementById('editCatDisplayName').value = cat.displayName || cat.name || cat.id;
  document.getElementById('editCatBaseFare').value = cat.baseFare !== undefined ? cat.baseFare : 0;
  document.getElementById('editCatPerKmRate').value = cat.perKmRate !== undefined ? cat.perKmRate : 15;
  document.getElementById('editCatMinimumFare').value = cat.minimumFare !== undefined ? cat.minimumFare : 60;
  document.getElementById('editCatHourlyWaiting').value = cat.hourlyWaitingCharge !== undefined ? cat.hourlyWaitingCharge : 60;
  document.getElementById('editCatCancellationFee').value = cat.cancellationFee !== undefined ? cat.cancellationFee : 30;

  document.getElementById('editCategoryModalTitle').innerText = `Edit ${cat.displayName || cat.name || cat.id} Fares`;
  document.getElementById('modalEditCategoryPricing').style.display = 'flex';
}

function closeEditCategoryModal() {
  document.getElementById('modalEditCategoryPricing').style.display = 'none';
}

async function saveCategoryPricingFromModal() {
  const catId = document.getElementById('editCatId').value;
  const catData = {
    displayName: document.getElementById('editCatDisplayName').value,
    baseFare: parseFloat(document.getElementById('editCatBaseFare').value) || 0,
    perKmRate: parseFloat(document.getElementById('editCatPerKmRate').value) || 15,
    minimumFare: parseFloat(document.getElementById('editCatMinimumFare').value) || 60,
    hourlyWaitingCharge: parseFloat(document.getElementById('editCatHourlyWaiting').value) || 60,
    cancellationFee: parseFloat(document.getElementById('editCatCancellationFee').value) || 30,
    isActive: true,
  };

  try {
    await apiSaveVehicleCategory(catId, catData);
    closeEditCategoryModal();
    renderCategoryPricingTable();
    showToast(`✅ ${catData.displayName} fares updated successfully!`);
  } catch (e) {
    showToast(`Failed to update category: ${e.message}`, 'error');
  }
}

/**
 * SDUI Festive Theme Studio Handlers
 */
function syncFestiveThemeToUI(theme) {
  if (!theme) return;

  const toggle = document.getElementById('festiveThemeEnabledToggle');
  if (toggle && toggle.checked !== (theme.enabled === true)) {
    toggle.checked = (theme.enabled === true);
  }

  const tapToggle = document.getElementById('festiveThemeInteractiveTap');
  if (tapToggle && tapToggle.checked !== (theme.interactiveTap !== false)) {
    tapToggle.checked = (theme.interactiveTap !== false);
  }

  const nameEl = document.getElementById('festiveThemeName');
  if (nameEl && !nameEl.matches(':focus')) {
    nameEl.value = theme.theme || 'diwali_rockets';
  }

  const durationRange = document.getElementById('festiveThemeDurationRange');
  const durationVal = document.getElementById('festiveThemeDurationVal');
  if (durationRange && !durationRange.matches(':focus')) {
    durationRange.value = theme.durationSeconds || 8;
    if (durationVal) durationVal.innerText = `${theme.durationSeconds || 8}s`;
  }

  const greetingEl = document.getElementById('festiveThemeGreeting');
  if (greetingEl && !greetingEl.matches(':focus')) {
    greetingEl.value = theme.greetingText || '✨ Shubh Deepawali from District Car ✨';
  }

  // Media / GIF
  const showMediaToggle = document.getElementById('festiveThemeShowMedia');
  if (showMediaToggle && showMediaToggle.checked !== (theme.showMedia === true)) {
    showMediaToggle.checked = (theme.showMedia === true);
  }

  const mediaUrlEl = document.getElementById('festiveThemeMediaUrl');
  if (mediaUrlEl && !mediaUrlEl.matches(':focus')) {
    mediaUrlEl.value = theme.mediaUrl || '';
  }

  const mediaPosEl = document.getElementById('festiveThemeMediaPos');
  if (mediaPosEl) {
    mediaPosEl.value = theme.mediaPosition || 'center';
  }

  const mediaAnimEl = document.getElementById('festiveThemeMediaAnim');
  if (mediaAnimEl) {
    mediaAnimEl.value = theme.mediaAnimation || 'pulse';
  }

  // Colors
  const primaryCol = document.getElementById('festiveThemePrimaryColor');
  if (primaryCol && theme.primaryColor) {
    primaryCol.value = theme.primaryColor;
  }

  const secCol = document.getElementById('festiveThemeSecondaryColor');
  if (secCol && theme.secondaryColor) {
    secCol.value = theme.secondaryColor;
  }

  const countEl = document.getElementById('festiveThemeRocketCount');
  if (countEl && !countEl.matches(':focus')) {
    countEl.value = theme.rocketCount || 6;
  }

  const densityEl = document.getElementById('festiveThemeSparkleDensity');
  if (densityEl && !densityEl.matches(':focus')) {
    densityEl.value = theme.sparkleDensity || 45;
  }

  const jsonArea = document.getElementById('festiveThemeJsonArea');
  if (jsonArea && !jsonArea.matches(':focus')) {
    jsonArea.value = JSON.stringify(theme, null, 2);
  }

  const badge = document.getElementById('festiveThemeStatusBadge');
  if (badge) {
    if (theme.enabled) {
      badge.style.background = '#ECFDF5';
      badge.style.borderColor = '#A7F3D0';
      badge.style.color = '#059669';
      badge.innerHTML = '<i class="fa-solid fa-circle-check"></i> OVERLAY LIVE IN APP';
    } else {
      badge.style.background = '#F1F5F9';
      badge.style.borderColor = '#CBD5E1';
      badge.style.color = '#64748B';
      badge.innerHTML = '<i class="fa-solid fa-circle-pause"></i> OVERLAY DISABLED';
    }
  }
}

function syncFestiveFormToJson() {
  const showMedia = Boolean(document.getElementById('festiveThemeShowMedia')?.checked);
  const mediaUrl = document.getElementById('festiveThemeMediaUrl')?.value?.trim();

  const current = {
    enabled: Boolean(document.getElementById('festiveThemeEnabledToggle')?.checked),
    theme: document.getElementById('festiveThemeName')?.value || 'diwali_rockets',
    durationSeconds: parseInt(document.getElementById('festiveThemeDurationRange')?.value, 10) || 8,
    interactiveTap: Boolean(document.getElementById('festiveThemeInteractiveTap')?.checked),
    enableHaptics: true,
    showGreetingBadge: true,
    greetingText: document.getElementById('festiveThemeGreeting')?.value || '✨ Shubh Deepawali from District Car ✨',
    showMedia: showMedia || Boolean(mediaUrl),
    mediaUrl: mediaUrl || undefined,
    mediaPosition: document.getElementById('festiveThemeMediaPos')?.value || 'center',
    mediaAnimation: document.getElementById('festiveThemeMediaAnim')?.value || 'pulse',
    mediaWidth: 150,
    mediaHeight: 150,
    colors: [
      document.getElementById('festiveThemePrimaryColor')?.value || '#FFD700',
      document.getElementById('festiveThemeSecondaryColor')?.value || '#FF4500',
      '#FF1493',
      '#00E676',
      '#FFFFFF'
    ],
    primaryColor: document.getElementById('festiveThemePrimaryColor')?.value || '#FFD700',
    secondaryColor: document.getElementById('festiveThemeSecondaryColor')?.value || '#FF4500',
    sparkleColor: '#FFFFFF',
    rocketCount: parseInt(document.getElementById('festiveThemeRocketCount')?.value, 10) || 6,
    sparkleDensity: parseInt(document.getElementById('festiveThemeSparkleDensity')?.value, 10) || 45,
    particleShape: 'stars',
  };

  const jsonArea = document.getElementById('festiveThemeJsonArea');
  if (jsonArea) {
    jsonArea.value = JSON.stringify(current, null, 2);
  }

  const badge = document.getElementById('festiveThemeStatusBadge');
  if (badge) {
    if (current.enabled) {
      badge.style.background = '#ECFDF5';
      badge.style.borderColor = '#A7F3D0';
      badge.style.color = '#059669';
      badge.innerHTML = '<i class="fa-solid fa-circle-check"></i> OVERLAY LIVE IN APP';
    } else {
      badge.style.background = '#F1F5F9';
      badge.style.borderColor = '#CBD5E1';
      badge.style.color = '#64748B';
      badge.innerHTML = '<i class="fa-solid fa-circle-pause"></i> OVERLAY DISABLED';
    }
  }
}

function syncJsonToFestiveForm() {
  const jsonArea = document.getElementById('festiveThemeJsonArea');
  if (!jsonArea) return;
  try {
    const parsed = JSON.parse(jsonArea.value);
    if (parsed && typeof parsed === 'object') {
      if (parsed.enabled !== undefined) {
        const toggle = document.getElementById('festiveThemeEnabledToggle');
        if (toggle) toggle.checked = Boolean(parsed.enabled);
      }
      if (parsed.interactiveTap !== undefined) {
        const tapToggle = document.getElementById('festiveThemeInteractiveTap');
        if (tapToggle) tapToggle.checked = Boolean(parsed.interactiveTap);
      }
      if (parsed.theme) {
        const n = document.getElementById('festiveThemeName');
        if (n) n.value = parsed.theme;
      }
      if (parsed.durationSeconds) {
        const d = document.getElementById('festiveThemeDurationRange');
        const dv = document.getElementById('festiveThemeDurationVal');
        if (d) d.value = parsed.durationSeconds;
        if (dv) dv.innerText = `${parsed.durationSeconds}s`;
      }
      if (parsed.greetingText) {
        const g = document.getElementById('festiveThemeGreeting');
        if (g) g.value = parsed.greetingText;
      }
      if (parsed.showMedia !== undefined) {
        const sm = document.getElementById('festiveThemeShowMedia');
        if (sm) sm.checked = Boolean(parsed.showMedia);
      }
      if (parsed.mediaUrl !== undefined) {
        const mu = document.getElementById('festiveThemeMediaUrl');
        if (mu) mu.value = parsed.mediaUrl;
      }
      if (parsed.mediaPosition) {
        const mp = document.getElementById('festiveThemeMediaPos');
        if (mp) mp.value = parsed.mediaPosition;
      }
      if (parsed.mediaAnimation) {
        const ma = document.getElementById('festiveThemeMediaAnim');
        if (ma) ma.value = parsed.mediaAnimation;
      }
      if (parsed.primaryColor) {
        const p = document.getElementById('festiveThemePrimaryColor');
        if (p) p.value = parsed.primaryColor;
      }
      if (parsed.secondaryColor) {
        const s = document.getElementById('festiveThemeSecondaryColor');
        if (s) s.value = parsed.secondaryColor;
      }
      if (parsed.rocketCount) {
        const rc = document.getElementById('festiveThemeRocketCount');
        if (rc) rc.value = parsed.rocketCount;
      }
      if (parsed.sparkleDensity) {
        const sd = document.getElementById('festiveThemeSparkleDensity');
        if (sd) sd.value = parsed.sparkleDensity;
      }
    }
  } catch (_) {
    // User typing, ignore until valid JSON
  }
}

function formatFestiveJsonTextarea() {
  const jsonArea = document.getElementById('festiveThemeJsonArea');
  if (!jsonArea) return;
  try {
    const obj = JSON.parse(jsonArea.value);
    jsonArea.value = JSON.stringify(obj, null, 2);
    showToast('JSON formatted cleanly');
  } catch (e) {
    showToast('Invalid JSON: ' + e.message, 'error');
  }
}

// =================== PRESETS ===================

function loadDefaultDiwaliTheme() {
  const diwaliPreset = {
    enabled: true,
    theme: "diwali_rockets",
    title: "Happy Diwali!",
    durationSeconds: 10,
    interactiveTap: true,
    enableHaptics: true,
    showGreetingBadge: true,
    greetingText: "✨ Shubh Deepawali from District Car ✨",
    showMedia: true,
    mediaUrl: "https://media.giphy.com/media/xT0xeJpnrWC4XWblEk/giphy.gif",
    mediaPosition: "center",
    mediaAnimation: "pulse",
    mediaWidth: 150,
    mediaHeight: 150,
    colors: ["#FFD700", "#FF4500", "#FF1493", "#00E676", "#FFFFFF"],
    primaryColor: "#FFD700",
    secondaryColor: "#FF4500",
    sparkleColor: "#FFFFFF",
    rocketCount: 8,
    sparkleDensity: 55,
    particleShape: "stars"
  };
  syncFestiveThemeToUI(diwaliPreset);
  showToast('🎆 Diwali Grand Fireworks & Diya GIF Preset Loaded');
}

function loadNewYearTheme() {
  const newYearPreset = {
    enabled: true,
    theme: "new_year_2027",
    title: "Happy New Year!",
    durationSeconds: 10,
    interactiveTap: true,
    enableHaptics: true,
    showGreetingBadge: true,
    greetingText: "🎉 Happy New Year from District Car! 🎉",
    showMedia: true,
    mediaUrl: "https://media.giphy.com/media/26tOZ42Mg6pbTUPHW/giphy.gif",
    mediaPosition: "center",
    mediaAnimation: "bounce",
    mediaWidth: 160,
    mediaHeight: 160,
    colors: ["#38BDF8", "#F43F5E", "#EAB308", "#A855F7", "#FFFFFF"],
    primaryColor: "#38BDF8",
    secondaryColor: "#F43F5E",
    sparkleColor: "#FFFFFF",
    rocketCount: 8,
    sparkleDensity: 60,
    particleShape: "confetti"
  };
  syncFestiveThemeToUI(newYearPreset);
  showToast('🍾 New Year Countdown & Confetti Preset Loaded');
}

function loadHoliTheme() {
  const holiPreset = {
    enabled: true,
    theme: "holi_color_splash",
    title: "Happy Holi!",
    durationSeconds: 9,
    interactiveTap: true,
    enableHaptics: true,
    showGreetingBadge: true,
    greetingText: "🌈 Happy Holi! Rangon Ka Tyohar Mubarak 🌈",
    showMedia: false,
    mediaPosition: "center",
    mediaAnimation: "pulse",
    colors: ["#EC4899", "#8B5CF6", "#10B981", "#F59E0B", "#EF4444"],
    primaryColor: "#EC4899",
    secondaryColor: "#10B981",
    sparkleColor: "#FFFFFF",
    rocketCount: 10,
    sparkleDensity: 70,
    particleShape: "sparks"
  };
  syncFestiveThemeToUI(holiPreset);
  showToast('🎨 Holi Color Splash Preset Loaded');
}

function loadCustomGifTheme() {
  const customPreset = {
    enabled: true,
    theme: "custom_festive_promo",
    title: "District Car Festival Special",
    durationSeconds: 12,
    interactiveTap: true,
    enableHaptics: true,
    showGreetingBadge: true,
    greetingText: "⚡ 35% Flat Discount on Round Trips! ⚡",
    showMedia: true,
    mediaUrl: "https://media.giphy.com/media/l41JGlwa1xYhkAJB6/giphy.gif",
    mediaPosition: "bottom",
    mediaAnimation: "float",
    mediaWidth: 160,
    mediaHeight: 160,
    showPromoCard: true,
    promoTitle: "FESTIVE SUPER SAVER",
    promoSubtitle: "Save 35% on all Round Trips across Jharkhand",
    promoCouponCode: "FESTIVE35",
    colors: ["#F59E0B", "#10B981", "#3B82F6", "#EC4899", "#FFFFFF"],
    primaryColor: "#F59E0B",
    secondaryColor: "#10B981",
    sparkleColor: "#FFFFFF",
    rocketCount: 7,
    sparkleDensity: 50,
    particleShape: "stars"
  };
  syncFestiveThemeToUI(customPreset);
  showToast('🎁 Custom Animated Sticker & Promo Preset Loaded');
}

async function publishFestiveThemeJson() {
  const jsonArea = document.getElementById('festiveThemeJsonArea');
  if (!jsonArea) return;

  let parsed;
  try {
    parsed = JSON.parse(jsonArea.value);
  } catch (e) {
    showToast('JSON Syntax Error: ' + e.message, 'error');
    return;
  }

  try {
    await apiSaveFestiveTheme(parsed);
    syncFestiveThemeToUI(parsed);
    showToast('🚀 Festive Theme SDUI published live to Customer App!');
  } catch (e) {
    showToast('Failed to publish festive theme: ' + e.message, 'error');
  }
}
