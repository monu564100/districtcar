/**
 * District Car Admin Web — Core Application & UI Controller
 * Includes Driver Commissions & Settlements, KYC Verification, and Ride Accounting
 */

document.addEventListener('DOMContentLoaded', () => {
  // 1. Initialize UI Elements & Event Listeners
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

    html += `
      <tr>
        <td>
          <strong style="color:#059669; font-size:14px;">${b.readableId || b.id.substring(0, 8)}</strong>
          ${b.rideOtp ? `<span style="display:block; font-size:11px; color:#64748B; font-weight:700;">OTP: <span style="background:#FEF08A; padding:1px 5px; border-radius:3px; color:#064E3B;">${b.rideOtp}</span></span>` : ''}
        </td>
        <td>
          <strong style="display:block; color:#0F172A;">${b.customerName || 'Customer'}</strong>
          <a href="tel:${b.customerPhone}" style="color:#64748B; font-size:12px; text-decoration:none;">
            <i class="fa-solid fa-phone" style="color:#059669;"></i> ${b.customerPhone || 'N/A'}
          </a>
        </td>
        <td>
          ${dName ? `
            <strong style="display:block; color:#0F172A;">${dName}</strong>
            <a href="tel:${b.driverPhone}" style="color:#64748B; font-size:12px; text-decoration:none;">
              <i class="fa-solid fa-phone" style="color:#059669;"></i> ${b.driverPhone || ''}
            </a>
          ` : '<span style="color:#94A3B8; font-style:italic;">Not Assigned</span>'}
        </td>
        <td>
          <span class="badge-category">${(b.vehicleCategoryId || 'CAB').toUpperCase()}</span>
          ${b.isRoundTrip ? '<span class="badge badge-info" style="margin-left:4px;">Round Trip</span>' : ''}
        </td>
        <td style="max-width:240px;">
          <div style="font-size:12.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">
            <i class="fa-solid fa-location-dot" style="color:#059669; width:14px;"></i> ${pickupStr}
          </div>
          <div style="font-size:12.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; color:#64748B; margin-top:2px;">
            <i class="fa-solid fa-flag-checkered" style="color:#DC2626; width:14px;"></i> ${destStr}
          </div>
        </td>
        <td>${statusChip}</td>
        <td><strong style="font-size:14px; color:#0F172A;">₹${grossFare.toFixed(0)}</strong></td>
        <td><strong style="font-size:14px; color:#B91C1C;">₹${comm10.toFixed(0)}</strong></td>
        <td><strong style="font-size:14px; color:#059669;">₹${driver90.toFixed(0)}</strong></td>
        <td>
          <button class="btn btn-secondary btn-sm" onclick="openBookingAuditModal('${b.id}')">
            <i class="fa-solid fa-receipt"></i> Details
          </button>
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
}

/**
 * 12. Modal Handlers
 */
function openDriverModal(driverId) {
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

function openBookingAuditModal(bookingId) {
  const b = AdminStore.bookings.find(x => x.id === bookingId);
  if (!b) return;

  const dName = b.driverName ? b.driverName : (b.driverId ? `Driver #${b.driverId.substring(0, 6)}` : 'Unassigned');

  safeSetText('auditBookingId', b.readableId || b.id);
  safeSetText('auditCustomer', `${b.customerName || 'Customer'} (${b.customerPhone || 'N/A'})`);
  safeSetText('auditDriver', `${dName} (${b.driverPhone || 'N/A'})`);
  safeSetText('auditPickup', b.pickup?.address || 'N/A');
  safeSetText('auditDestination', b.destination?.address || 'N/A');
  safeSetText('auditOTP', b.rideOtp || 'N/A');

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

  try {
    await apiSaveRemoteConfig(dBuild, cBuild, force, apk);
    showToast(`Remote version updated: Driver App v${dBuild}, Customer App v${cBuild}!`);
  } catch (e) {
    alert('Failed to save configuration: ' + e.message);
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

  let csv = 'BookingID,Date,CustomerName,CustomerPhone,DriverName,Category,Status,GrossFare,Commission10,DriverNet90,PaymentMethod\n';
  list.forEach(b => {
    const gross = parseFloat(b.finalFare || b.estimatedFare || 0);
    const dateStr = b.createdAt ? new Date(b.createdAt.seconds ? b.createdAt.seconds * 1000 : b.createdAt).toISOString() : '';
    csv += `"${b.readableId || b.id}","${dateStr}","${b.customerName || ''}","${b.customerPhone || ''}","${b.driverName || ''}","${b.vehicleCategoryId || ''}","${b.status}","${gross}","${(gross*0.1).toFixed(0)}","${(gross*0.9).toFixed(0)}","${b.paymentMethod || 'cash'}"\n`;
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
